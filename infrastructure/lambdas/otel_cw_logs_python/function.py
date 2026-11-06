import base64
import gzip
import json
import logging
import os
import re
import time
import urllib.error
import urllib.request
from typing import Any

import grpc
from opentelemetry.proto.collector.logs.v1 import (
    logs_service_pb2,
    logs_service_pb2_grpc,
)
from opentelemetry.proto.collector.metrics.v1 import (
    metrics_service_pb2,
    metrics_service_pb2_grpc,
)
from opentelemetry.proto.common.v1 import common_pb2
from opentelemetry.proto.logs.v1 import logs_pb2
from opentelemetry.proto.metrics.v1 import metrics_pb2
from opentelemetry.proto.resource.v1 import resource_pb2

logger = logging.getLogger()
logger.setLevel(logging.INFO)

OTLP_ENDPOINT = os.environ.get("OTLP_ENDPOINT", "")
OTLP_AUTH_TOKEN = os.environ.get("OTLP_AUTH_TOKEN", "")
OTLP_AUTH_TOKEN_MAP_ENV = os.environ.get("OTLP_AUTH_TOKEN_MAP", "")
OTLP_AUTH_TOKEN_SECRET_ARN_MAP_ENV = os.environ.get(
    "OTLP_AUTH_TOKEN_SECRET_ARN_MAP", ""
)
LOG_GROUP_AUTH_TOKEN_MAP_ENV = os.environ.get("LOG_GROUP_AUTH_TOKEN_MAP", "")
OTEL_ATTRIBUTE_AUTH_TOKEN_MAP_ENV = os.environ.get("OTEL_ATTRIBUTE_AUTH_TOKEN_MAP", "")

OTEL_RESOURCE_ATTRIBUTES_ENV = os.environ.get("OTEL_RESOURCE_ATTRIBUTES", "")
LOG_GROUP_RESOURCE_ATTRIBUTES_ENV = os.environ.get("LOG_GROUP_RESOURCE_ATTRIBUTES", "")

OTLP_PROTOCOL = os.environ.get("OTLP_PROTOCOL", "grpc")

RATE_LIMIT_ENV = os.environ.get("RATE_LIMIT", "")
SANITIZE_FOR_LOG_REGEX = re.compile(r"[A-Za-z0-9._:/+=-]", re.ASCII)


def _parse_rate_limit(env: str) -> float:
    """Parse the ``RATE_LIMIT`` env var (pushes per second).

    Returns the rate as a float.  ``0`` (or empty / unparseable) means
    unlimited."""
    stripped = env.strip()
    if not stripped:
        return 0.0
    try:
        value = float(stripped)
        return max(value, 0.0)
    except ValueError:
        logger.warning(
            f"Invalid RATE_LIMIT value '{stripped}', defaulting to unlimited"
        )
        return 0.0


RATE_LIMIT: float = _parse_rate_limit(RATE_LIMIT_ENV)


class RateLimiter:
    """Simple token-bucket-style rate limiter for pacing OTLP pushes.

    Tracks the time of the last send and sleeps before the next send if the
    minimum interval has not elapsed.  Thread-safety is not needed since Lambda
    handlers execute in a single thread."""

    def __init__(self, rate: float) -> None:
        self._min_interval: float = 1.0 / rate if rate > 0 else 0.0
        self._last_send: float = 0.0

    def wait(self) -> None:
        """Block until the next send is allowed."""
        if self._min_interval <= 0:
            return
        now = time.monotonic()
        elapsed = now - self._last_send
        if elapsed < self._min_interval:
            time.sleep(self._min_interval - elapsed)
        self._last_send = time.monotonic()


_rate_limiter = RateLimiter(RATE_LIMIT)


def _parse_resource_attributes(env: str) -> dict[str, str]:
    if not env.strip():
        return {}
    return {
        k: v
        for k, v in (pair.strip().split("=") for pair in env.strip().split(","))
        if v
    }


class LogGroupSelector:
    """A log-group selector using a compiled regex."""

    __slots__ = ("pattern",)

    def __init__(self, pattern: re.Pattern[str]) -> None:
        self.pattern = pattern

    def matches_log_group(self, log_group: str) -> bool:
        return self.pattern.search(log_group) is not None


class LogGroupAuthTokenMapping:
    """Map a log-group selector to a named auth token."""

    __slots__ = ("selector", "token_name")

    def __init__(self, token_name: str, selector: LogGroupSelector) -> None:
        self.token_name = token_name
        self.selector = selector

    def matches_log_group(self, log_group: str) -> bool:
        return self.selector.matches_log_group(log_group)


class AttributeAuthTokenMapping:
    """Map a resource-attribute matcher to a named auth token."""

    __slots__ = ("attr_key", "token_name", "value_pattern")

    def __init__(
        self, attr_key: str, value_pattern: re.Pattern[str], token_name: str
    ) -> None:
        self.attr_key = attr_key
        self.value_pattern = value_pattern
        self.token_name = token_name

    def matches_attributes(self, attrs: dict[str, str]) -> bool:
        value = attrs.get(self.attr_key)
        if value is None:
            return False
        return self.value_pattern.search(value) is not None


def _normalize_log_group_selector_pattern(selector: str) -> str:
    """Normalize selector strings used by log-group keyed maps.

    Keys are treated as regex patterns. If a key starts with ``/``, prefix
    ``^`` so the match is pinned to the start of the log group.
    """
    if not selector.endswith("$"):
        selector = f"{selector}$"
    if selector.startswith("/"):
        return f"^{selector}"
    return selector


def _parse_auth_token_map(
    otlp_auth_token: str, otlp_auth_token_map_env: str
) -> dict[str, str]:
    """Parse auth token config from OTLP_AUTH_TOKEN or OTLP_AUTH_TOKEN_MAP."""
    single = otlp_auth_token.strip()
    mapped = otlp_auth_token_map_env.strip()

    if single and mapped:
        raise ValueError("Set either OTLP_AUTH_TOKEN or OTLP_AUTH_TOKEN_MAP, not both")

    if single:
        return {"default": single}

    if not mapped:
        raise ValueError("Set OTLP_AUTH_TOKEN or OTLP_AUTH_TOKEN_MAP")

    raw = json.loads(mapped)
    if not isinstance(raw, dict):
        raise ValueError("OTLP_AUTH_TOKEN_MAP must be a JSON object")

    parsed = {
        name.strip(): token.strip()
        for name, token in raw.items()
        if isinstance(name, str)
        and isinstance(token, str)
        and name.strip()
        and token.strip()
    }
    if "default" not in parsed:
        raise ValueError("OTLP_AUTH_TOKEN_MAP must include a non-empty 'default' token")
    return parsed


def _parse_auth_token_secret_arn_map(env: str) -> dict[str, str]:
    if not env.strip():
        return {}
    raw = json.loads(env)
    if not isinstance(raw, dict):
        raise ValueError("OTLP_AUTH_TOKEN_SECRET_ARN_MAP must be a JSON object")
    parsed = {
        name.strip(): arn.strip()
        for name, arn in raw.items()
        if isinstance(name, str)
        and isinstance(arn, str)
        and name.strip()
        and arn.strip()
    }
    if "default" not in parsed:
        raise ValueError(
            "OTLP_AUTH_TOKEN_SECRET_ARN_MAP must include a non-empty 'default' ARN"
        )
    if any(
        not re.fullmatch(r"arn:[^:]+:secretsmanager:[^:]+:\d{12}:secret:.+", arn)
        for arn in parsed.values()
    ):
        raise ValueError(
            "OTLP_AUTH_TOKEN_SECRET_ARN_MAP values must be Secrets Manager ARNs"
        )
    return parsed


def _get_auth_token(token_name: str) -> str:
    token = AUTH_TOKEN_MAP.get(token_name, "").strip()
    if token:
        return token
    secret_arn = AUTH_TOKEN_SECRET_ARN_MAP.get(token_name)
    if not secret_arn:
        raise ValueError(f"No auth token is configured for token name '{token_name}'")

    now = time.monotonic()
    cached = _secret_cache.get(secret_arn)
    if cached is not None and cached[0] > now:
        return cached[1]

    global _secrets_manager_client
    if _secrets_manager_client is None:
        import boto3

        _secrets_manager_client = boto3.client("secretsmanager")
    response = _secrets_manager_client.get_secret_value(SecretId=secret_arn)
    secret = response.get("SecretString")
    if not isinstance(secret, str) or not secret.strip():
        raise ValueError("The configured OTLP auth secret has no non-empty SecretString")
    _secret_cache[secret_arn] = (now + AUTH_TOKEN_CACHE_TTL_SECONDS, secret.strip())
    return secret.strip()


def _parse_log_group_auth_token_mappings(env: str) -> list[LogGroupAuthTokenMapping]:
    """Parse LOG_GROUP_AUTH_TOKEN_MAP as a {selector: token_name} JSON object."""
    stripped = env.strip()
    if not stripped:
        return []
    raw = json.loads(stripped)
    if not isinstance(raw, dict):
        return []

    mappings: list[LogGroupAuthTokenMapping] = []
    for selector, token_name in raw.items():
        if (
            not isinstance(selector, str)
            or not selector.strip()
            or not isinstance(token_name, str)
            or not token_name.strip()
        ):
            continue
        selector_text = _normalize_log_group_selector_pattern(selector.strip())
        parsed_selector = LogGroupSelector(re.compile(selector_text))
        mappings.append(
            LogGroupAuthTokenMapping(
                token_name=token_name.strip(), selector=parsed_selector
            )
        )
    return mappings


def _parse_attribute_auth_token_mappings(
    env: str,
) -> list[AttributeAuthTokenMapping]:
    """Parse OTEL_ATTRIBUTE_AUTH_TOKEN_MAP as {key=regex: token_name}."""
    stripped = env.strip()
    if not stripped:
        return []
    raw = json.loads(stripped)
    if not isinstance(raw, dict):
        return []

    mappings: list[AttributeAuthTokenMapping] = []
    for attr_spec, token_name in raw.items():
        if (
            not isinstance(attr_spec, str)
            or not attr_spec.strip()
            or not isinstance(token_name, str)
            or not token_name.strip()
        ):
            continue
        attr_key, sep, value_pattern = attr_spec.partition("=")
        attr_key = attr_key.strip()
        value_pattern = value_pattern.strip()
        if not sep or not attr_key or not value_pattern:
            continue
        mappings.append(
            AttributeAuthTokenMapping(
                attr_key=attr_key,
                value_pattern=re.compile(value_pattern),
                token_name=token_name.strip(),
            )
        )
    return mappings


def _validate_log_group_auth_token_mappings(
    mappings: list[LogGroupAuthTokenMapping], auth_token_map: dict[str, str]
) -> None:
    """Validate mapping token names against OTLP_AUTH_TOKEN_MAP keys."""
    if any(m.token_name not in auth_token_map for m in mappings):
        raise ValueError("LOG_GROUP_AUTH_TOKEN_MAP references unknown auth token names")


def _validate_attribute_auth_token_mappings(
    mappings: list[AttributeAuthTokenMapping], auth_token_map: dict[str, str]
) -> None:
    """Validate mapping token names against OTLP_AUTH_TOKEN_MAP keys."""
    if any(m.token_name not in auth_token_map for m in mappings):
        raise ValueError(
            "OTEL_ATTRIBUTE_AUTH_TOKEN_MAP references unknown auth token names"
        )


OTEL_RESOURCE_ATTRIBUTES = _parse_resource_attributes(OTEL_RESOURCE_ATTRIBUTES_ENV)
AUTH_TOKEN_SECRET_ARN_MAP = _parse_auth_token_secret_arn_map(
    OTLP_AUTH_TOKEN_SECRET_ARN_MAP_ENV
)
if AUTH_TOKEN_SECRET_ARN_MAP and (OTLP_AUTH_TOKEN or OTLP_AUTH_TOKEN_MAP_ENV):
    raise ValueError("Set either direct OTLP auth tokens or secret ARN references, not both")
AUTH_TOKEN_MAP = (
    {}
    if AUTH_TOKEN_SECRET_ARN_MAP
    else _parse_auth_token_map(OTLP_AUTH_TOKEN, OTLP_AUTH_TOKEN_MAP_ENV)
)
TOKEN_NAME_MAP = AUTH_TOKEN_SECRET_ARN_MAP or AUTH_TOKEN_MAP
AUTH_TOKEN_CACHE_TTL_SECONDS = 300
_secret_cache: dict[str, tuple[float, str]] = {}
_secrets_manager_client: Any = None
LOG_GROUP_AUTH_TOKEN_MAPPINGS = _parse_log_group_auth_token_mappings(
    LOG_GROUP_AUTH_TOKEN_MAP_ENV
)
_validate_log_group_auth_token_mappings(LOG_GROUP_AUTH_TOKEN_MAPPINGS, TOKEN_NAME_MAP)
ATTRIBUTE_AUTH_TOKEN_MAPPINGS = _parse_attribute_auth_token_mappings(
    OTEL_ATTRIBUTE_AUTH_TOKEN_MAP_ENV
)
_validate_attribute_auth_token_mappings(ATTRIBUTE_AUTH_TOKEN_MAPPINGS, TOKEN_NAME_MAP)


def _default_auth_token() -> str:
    """Return the default auth token used when no selector matches."""
    return _get_auth_token("default")


def _resolve_auth_token_for_log_record(
    log_group: str,
    resource_attrs: dict[str, str],
    record_attrs: dict[str, str],
) -> str:
    """Resolve auth token using log-group selectors, then attribute selectors.

    Attributes are checked against the merged set of resource attributes and
    log record attributes (record attrs take precedence on key conflicts)."""
    selected_name = "default"
    for mapping in LOG_GROUP_AUTH_TOKEN_MAPPINGS:
        if mapping.matches_log_group(log_group):
            selected_name = mapping.token_name
    merged_attrs = {**resource_attrs, **record_attrs}
    for attr_mapping in ATTRIBUTE_AUTH_TOKEN_MAPPINGS:
        if attr_mapping.matches_attributes(merged_attrs):
            selected_name = attr_mapping.token_name
    return _get_auth_token(selected_name)


def _split_request_by_auth_token(
    request: logs_service_pb2.ExportLogsServiceRequest,
    log_group: str,
) -> dict[str, logs_service_pb2.ExportLogsServiceRequest]:
    """Group log records by resolved auth token into separate requests.

    Each log record is evaluated against the merged set of resource attributes
    and its own per-record attributes. Records mapping to the same auth token
    are batched into a single ExportLogsServiceRequest that shares the original
    request's resource."""
    resource_attrs: dict[str, str] = {}
    rl = request.resource_logs[0]
    if rl.HasField("resource"):
        resource_attrs = {a.key: a.value.string_value for a in rl.resource.attributes}

    batches: dict[str, list[logs_pb2.LogRecord]] = {}
    for sl in rl.scope_logs:
        for record in sl.log_records:
            record_attrs = {a.key: a.value.string_value for a in record.attributes}
            token = _resolve_auth_token_for_log_record(
                log_group, resource_attrs, record_attrs
            )
            batches.setdefault(token, []).append(record)

    result: dict[str, logs_service_pb2.ExportLogsServiceRequest] = {}
    for token, records in batches.items():
        scope_logs = logs_pb2.ScopeLogs(
            scope=rl.scope_logs[0].scope,
            log_records=records,
        )
        result[token] = logs_service_pb2.ExportLogsServiceRequest(
            resource_logs=[
                logs_pb2.ResourceLogs(
                    resource=rl.resource,
                    scope_logs=[scope_logs],
                )
            ]
        )
    return result


class ResourceAttributeMapping:
    """A resource-attribute override rule with a regex log-group selector."""

    __slots__ = ("attrs", "selector")

    def __init__(
        self,
        attrs: dict[str, str],
        selector: LogGroupSelector,
    ) -> None:
        self.attrs = attrs
        self.selector = selector

    def matches_log_group(self, log_group: str) -> bool:
        """Return True if this mapping applies to *log_group*."""
        return self.selector.matches_log_group(log_group)


def _parse_log_group_resource_attribute_mappings(
    env: str,
) -> list[ResourceAttributeMapping]:
    """Parse JSON mapping of log-group matchers to resource attributes.

    The env var must contain a JSON object where keys are regex patterns and
    values are ``key=value`` strings in the same format as
    ``OTEL_RESOURCE_ATTRIBUTES``. Keys starting with ``/`` are normalized to
    ``^/`` to pin matching to the start of the log group.
    """
    stripped = env.strip()
    if not stripped:
        return []
    raw = json.loads(stripped)
    if not isinstance(raw, dict):
        return []

    mappings: list[ResourceAttributeMapping] = []
    for matcher, attrs_env in raw.items():
        if not isinstance(matcher, str) or not isinstance(attrs_env, str):
            continue
        attrs = _parse_resource_attributes(attrs_env)
        if not attrs:
            continue

        selector_text = _normalize_log_group_selector_pattern(matcher.strip())
        mappings.append(
            ResourceAttributeMapping(
                attrs=attrs,
                selector=LogGroupSelector(re.compile(selector_text)),
            )
        )
    return mappings


LOG_GROUP_RESOURCE_ATTRIBUTE_MAPPINGS: list[ResourceAttributeMapping] = (
    _parse_log_group_resource_attribute_mappings(LOG_GROUP_RESOURCE_ATTRIBUTES_ENV)
)

LOG_GROUP_REGEX_ENV = os.environ.get("LOG_GROUP_REGEX", "")
LOG_GROUP_REGEX: re.Pattern[str] | None = (
    re.compile(LOG_GROUP_REGEX_ENV) if LOG_GROUP_REGEX_ENV else None
)

LOG_LINE_REGEX_ENV = os.environ.get("LOG_LINE_REGEX", "")


class RegexMapping:
    """A named-group regex extraction rule with an optional log group filter."""

    __slots__ = ("log_group_regex", "pattern")

    def __init__(
        self,
        pattern: re.Pattern[str],
        log_group_regex: re.Pattern[str] | None = None,
    ) -> None:
        self.pattern = pattern
        self.log_group_regex = log_group_regex

    def matches_log_group(self, log_group: str) -> bool:
        """Return True if this mapping applies to *log_group*."""
        if self.log_group_regex is None:
            return True
        return self.log_group_regex.search(log_group) is not None


def _parse_regex_mappings(env: str) -> list[RegexMapping]:
    """Parse ``LOG_LINE_REGEX`` into a list of :class:`RegexMapping`.

    Two formats are supported:

    **Simple** (a single regex string, applied to all log groups)::

        \\[(?P<severity__text>[A-Z]+)\\] (?P<trace__id>[a-f0-9]+)

    **JSON array** (each object has ``regex`` and an optional ``log_group``
    regex that restricts extraction to matching log groups)::

        [
          {"regex": "\\\\[(?P<severity__text>[A-Z]+)\\\\]"},
          {"regex": "requestId=(?P<request__id>[^ ]+)",
           "log_group": "^/aws/lambda/"}
        ]

    The format is auto-detected: if the trimmed value starts with ``[`` it is
    parsed as JSON, otherwise the simple format is used."""
    stripped = env.strip()
    if not stripped:
        return []

    if stripped.startswith("["):
        return _parse_regex_mappings_json(stripped)
    return [RegexMapping(re.compile(stripped))]


def _parse_regex_mappings_json(env: str) -> list[RegexMapping]:
    """Parse the JSON array format with optional per-entry ``log_group`` regex."""
    raw = json.loads(env)
    if not isinstance(raw, list):
        return []
    mappings: list[RegexMapping] = []
    for entry in raw:
        if not isinstance(entry, dict):
            continue
        regex_str = entry.get("regex", "").strip()
        if not regex_str:
            continue
        log_group_pattern = entry.get("log_group", "").strip()
        lg_regex = re.compile(log_group_pattern) if log_group_pattern else None
        mappings.append(RegexMapping(re.compile(regex_str), lg_regex))
    return mappings


LOG_LINE_REGEX_MAPPINGS: list[RegexMapping] = _parse_regex_mappings(LOG_LINE_REGEX_ENV)

LOG_LINE_JSON_PATHS_ENV = os.environ.get("LOG_LINE_JSON_PATHS", "")


class JsonPathMapping:
    """A single JSON path extraction rule with an optional log group filter."""

    __slots__ = ("attr_key", "log_group_regex", "path")

    def __init__(
        self,
        attr_key: str,
        path: list[str],
        log_group_regex: re.Pattern[str] | None = None,
    ) -> None:
        self.attr_key = attr_key
        self.path = path
        self.log_group_regex = log_group_regex

    def matches_log_group(self, log_group: str) -> bool:
        """Return True if this mapping applies to *log_group*."""
        if self.log_group_regex is None:
            return True
        return self.log_group_regex.search(log_group) is not None


def _parse_json_path_mappings(env: str) -> list[JsonPathMapping]:
    """Parse ``LOG_LINE_JSON_PATHS`` into a list of :class:`JsonPathMapping`.

    Two formats are supported:

    **Simple** (comma-separated ``attr=path`` pairs, no log group filter)::

        severity.text=level,trace.id=ctx.traceId

    **JSON array** (each object has ``attr``, ``path``, and an optional
    ``log_group`` regex that restricts extraction to matching log groups)::

        [
          {"attr": "severity.text", "path": "level"},
          {"attr": "request.id", "path": "ctx.requestId",
           "log_group": "^/aws/lambda/"}
        ]

    The format is auto-detected: if the trimmed value starts with ``[`` it is
    parsed as JSON, otherwise the simple format is used."""
    stripped = env.strip()
    if not stripped:
        return []

    if stripped.startswith("["):
        return _parse_json_path_mappings_json(stripped)
    return _parse_json_path_mappings_simple(stripped)


def _parse_json_path_mappings_simple(env: str) -> list[JsonPathMapping]:
    """Parse the simple ``attr=path,attr=path`` format (no log group filter)."""
    mappings: list[JsonPathMapping] = []
    for pair in env.split(","):
        pair = pair.strip()
        if "=" not in pair:
            continue
        attr_key, json_path = pair.split("=", 1)
        attr_key = attr_key.strip()
        json_path = json_path.strip()
        if attr_key and json_path:
            mappings.append(JsonPathMapping(attr_key, json_path.split(".")))
    return mappings


def _parse_json_path_mappings_json(env: str) -> list[JsonPathMapping]:
    """Parse the JSON array format with optional per-entry ``log_group`` regex."""
    raw = json.loads(env)
    if not isinstance(raw, list):
        return []
    mappings: list[JsonPathMapping] = []
    for entry in raw:
        if not isinstance(entry, dict):
            continue
        attr_key = entry.get("attr", "").strip()
        path_str = entry.get("path", "").strip()
        if not attr_key or not path_str:
            continue
        log_group_pattern = entry.get("log_group", "").strip()
        lg_regex = re.compile(log_group_pattern) if log_group_pattern else None
        mappings.append(JsonPathMapping(attr_key, path_str.split("."), lg_regex))
    return mappings


LOG_LINE_JSON_PATHS: list[JsonPathMapping] = _parse_json_path_mappings(
    LOG_LINE_JSON_PATHS_ENV
)


def _group_name_to_attr_key(name: str) -> str:
    """Convert a regex group name to an OTel attribute key.

    Regex group names cannot contain dots, so double underscores are used as a
    stand-in: ``service__name`` becomes ``service.name``,
    ``deployment__environment__name`` becomes ``deployment.environment.name``.
    Single underscores are left as-is."""
    return name.replace("__", ".")


def _extract_log_group_attributes(log_group: str) -> dict[str, str]:
    """Apply LOG_GROUP_REGEX to the log group name and return extracted attributes.

    Named capture groups are converted to attribute keys via
    :func:`_group_name_to_attr_key`.  Groups that did not participate in the
    match (value ``None``) or captured an empty string are skipped."""
    if LOG_GROUP_REGEX is None:
        return {}
    m = LOG_GROUP_REGEX.search(log_group)
    if m is None:
        return {}
    return {_group_name_to_attr_key(k): v for k, v in m.groupdict().items() if v}


def _extract_log_line_regex_attributes(
    message: str, log_group: str = ""
) -> dict[str, str]:
    """Apply ``LOG_LINE_REGEX`` mappings to a log message and return extracted attributes.

    Each :class:`RegexMapping` may carry its own ``log_group`` regex; mappings
    whose filter does not match the current log group are skipped.  When
    multiple mappings match, later entries overwrite earlier ones for the same
    attribute key.

    Named capture groups are converted to attribute keys via
    :func:`_group_name_to_attr_key`.  Groups that did not participate in the
    match (value ``None``) or captured an empty string are skipped."""
    if not LOG_LINE_REGEX_MAPPINGS:
        return {}
    attrs: dict[str, str] = {}
    for mapping in LOG_LINE_REGEX_MAPPINGS:
        if not mapping.matches_log_group(log_group):
            continue
        m = mapping.pattern.search(message)
        if m is None:
            continue
        attrs.update(
            {_group_name_to_attr_key(k): v for k, v in m.groupdict().items() if v}
        )
    return attrs


def _resolve_json_path(obj: Any, path: list[str]) -> Any:
    """Walk *obj* along the dot-separated *path* segments.

    Returns ``None`` when any segment is missing or the current node is not a
    dict, so callers never need to handle exceptions."""
    for segment in path:
        if not isinstance(obj, dict):
            return None
        obj = obj.get(segment)
        if obj is None:
            return None
    return obj


def _extract_log_line_json_attributes(
    message: str, log_group: str = ""
) -> dict[str, str]:
    """If *message* contains a JSON object, extract values at the configured
    ``LOG_LINE_JSON_PATHS`` and return them as string attributes.

    Each mapping may carry its own ``log_group`` regex; mappings whose filter
    does not match the current log group are skipped.

    The function looks for the first ``{`` in the line and attempts to parse
    from that position, so structured JSON log lines with a text prefix (e.g.
    a timestamp or level) are still handled.  Non-string values are converted
    with ``str()``.  Returns an empty dict when the message contains no
    parseable JSON object, or when none of the configured paths match."""
    if not LOG_LINE_JSON_PATHS:
        return {}
    brace = message.find("{")
    if brace == -1:
        return {}
    try:
        parsed = json.loads(message[brace:])
    except (json.JSONDecodeError, ValueError):
        return {}
    if not isinstance(parsed, dict):
        return {}
    attrs: dict[str, str] = {}
    for mapping in LOG_LINE_JSON_PATHS:
        if not mapping.matches_log_group(log_group):
            continue
        value = _resolve_json_path(parsed, mapping.path)
        if value is not None:
            attrs[mapping.attr_key] = value if isinstance(value, str) else str(value)
    return attrs


def _extract_log_line_attributes(
    message: str, log_group: str = ""
) -> list[common_pb2.KeyValue]:
    """Run all per-line extractors and return the merged attributes as KeyValues.

    ``LOG_LINE_REGEX`` is applied first, then ``LOG_LINE_JSON_PATHS``; if both
    produce the same key the JSON path value wins (more specific)."""
    merged = _extract_log_line_regex_attributes(message, log_group)
    merged.update(_extract_log_line_json_attributes(message, log_group))
    return [
        common_pb2.KeyValue(
            key=k,
            value=common_pb2.AnyValue(string_value=v),
        )
        for k, v in merged.items()
    ]


if not OTLP_ENDPOINT:
    logger.error("OTLP_ENDPOINT not configured")

DEFAULT_EXPORT_TIMEOUT_SECONDS = 60.0
DEADLINE_SAFETY_MARGIN_SECONDS = 10.0

# retry policy for the http/protobuf transport, mirroring the gRPC service config
HTTP_RETRY_ATTEMPTS = 5
HTTP_RETRY_BACKOFF_SECONDS = 1.0
HTTP_RETRYABLE_STATUSES = {429, 500, 502, 503, 504}

# retry transient failures inside gRPC rather than failing the whole batch
GRPC_SERVICE_CONFIG = json.dumps(
    {
        "methodConfig": [
            {
                "name": [
                    {"service": "opentelemetry.proto.collector.logs.v1.LogsService"}
                ],
                "retryPolicy": {
                    "maxAttempts": 5,
                    "initialBackoff": "1s",
                    "maxBackoff": "10s",
                    "backoffMultiplier": 2,
                    "retryableStatusCodes": ["UNAVAILABLE", "RESOURCE_EXHAUSTED"],
                },
            }
        ]
    }
)

_channel = None
_stub = None
_metrics_stub = None


def _get_channel() -> Any:
    """Create the gRPC channel once and reuse it across invocations."""
    global _channel
    if _channel is None:
        options = [
            ("grpc.service_config", GRPC_SERVICE_CONFIG),
            ("grpc.enable_retries", 1),
        ]
        target, use_tls = parse_endpoint(OTLP_ENDPOINT)
        if use_tls:
            _channel = grpc.secure_channel(
                target, grpc.ssl_channel_credentials(), options=options
            )
        else:
            _channel = grpc.insecure_channel(target, options=options)
    return _channel


def get_stub() -> logs_service_pb2_grpc.LogsServiceStub:
    """Create the gRPC logs stub once and reuse it across invocations."""
    global _stub
    if _stub is None:
        _stub = logs_service_pb2_grpc.LogsServiceStub(_get_channel())
    return _stub


def _get_metrics_stub() -> metrics_service_pb2_grpc.MetricsServiceStub:
    """Create the gRPC metrics stub once, sharing the same channel."""
    global _metrics_stub
    if _metrics_stub is None:
        _metrics_stub = metrics_service_pb2_grpc.MetricsServiceStub(_get_channel())
    return _metrics_stub


def parse_endpoint(endpoint: str) -> tuple[str, bool]:
    """Split an endpoint URL into (target, use_tls).

    https:// and grpcs:// use TLS; http:// and grpc:// are plaintext.
    A bare host:port defaults to TLS."""
    for scheme, use_tls in (
        ("https://", True),
        ("grpcs://", True),
        ("http://", False),
        ("grpc://", False),
    ):
        if endpoint.startswith(scheme):
            return endpoint.removeprefix(scheme), use_tls
    return endpoint, True


def decode_cw_logs_event(event: dict[str, Any]) -> dict[str, Any]:
    """Decode a CloudWatch Logs subscription filter event.

    The ``awslogs.data`` field is base64-encoded, gzipped JSON containing the
    log group, log stream, owner (account id) and log events."""
    compressed = base64.b64decode(event["awslogs"]["data"])
    return json.loads(gzip.decompress(compressed))  # type: ignore[no-any-return]


def _build_resource(
    log_group: str,
    owner: str,
    region: str,
) -> resource_pb2.Resource:
    """Build an OTLP Resource with standard cloud attributes.

    ``service.name`` defaults to the CloudWatch log group name so that logs are
    automatically grouped by the originating log group in observability backends."""
    attrs = [
        common_pb2.KeyValue(
            key="service.name",
            value=common_pb2.AnyValue(string_value=log_group),
        ),
        common_pb2.KeyValue(
            key="cloud.provider",
            value=common_pb2.AnyValue(string_value="aws"),
        ),
        common_pb2.KeyValue(
            key="cloud.region",
            value=common_pb2.AnyValue(string_value=region),
        ),
        common_pb2.KeyValue(
            key="cloud.account.id",
            value=common_pb2.AnyValue(string_value=owner),
        ),
    ]

    resource = resource_pb2.Resource()
    resource.attributes.extend(attrs)
    return resource


def _merge_resource_attributes(resource: Any, attrs: dict[str, str]) -> None:
    """Merge a dict of attributes into a Resource, overwriting duplicates."""
    if not attrs:
        return
    remaining = attrs.copy()
    for attr in resource.attributes:
        if attr.key not in remaining:
            continue
        attr.value.string_value = remaining[attr.key]
        del remaining[attr.key]
    for key, value in remaining.items():
        resource.attributes.append(
            common_pb2.KeyValue(
                key=key,
                value=common_pb2.AnyValue(string_value=value),
            )
        )


def _set_resource_attributes(resource: Any) -> None:
    """Merge OTEL_RESOURCE_ATTRIBUTES into the resource, overwriting duplicates."""
    _merge_resource_attributes(resource, OTEL_RESOURCE_ATTRIBUTES)


def _set_log_group_resource_attributes(resource: Any, log_group: str) -> None:
    """Merge matching log-group resource overrides, overwriting duplicates."""
    merged: dict[str, str] = {}
    for mapping in LOG_GROUP_RESOURCE_ATTRIBUTE_MAPPINGS:
        if mapping.matches_log_group(log_group):
            merged.update(mapping.attrs)
    _merge_resource_attributes(resource, merged)


def build_export_request(
    payload: dict[str, Any],
    region: str,
) -> logs_service_pb2.ExportLogsServiceRequest:
    """Transform a decoded CloudWatch Logs payload into an OTLP ExportLogsServiceRequest."""
    log_group: str = payload["logGroup"]
    log_stream: str = payload["logStream"]
    owner: str = payload["owner"]
    log_events: list[dict[str, Any]] = payload["logEvents"]

    resource = _build_resource(log_group, owner, region)
    _merge_resource_attributes(resource, _extract_log_group_attributes(log_group))
    _set_resource_attributes(resource)
    _set_log_group_resource_attributes(resource, log_group)

    now_ns = int(time.time() * 1e9)

    log_records: list[logs_pb2.LogRecord] = []
    for ev in log_events:
        # CloudWatch timestamps are milliseconds; OTLP needs nanoseconds
        timestamp_ns = int(ev["timestamp"]) * 1_000_000
        message: str = ev["message"]
        record = logs_pb2.LogRecord(
            time_unix_nano=timestamp_ns,
            observed_time_unix_nano=now_ns,
            body=common_pb2.AnyValue(string_value=message),
            attributes=[
                common_pb2.KeyValue(
                    key="aws.cloudwatch.log_group",
                    value=common_pb2.AnyValue(string_value=log_group),
                ),
                common_pb2.KeyValue(
                    key="aws.cloudwatch.log_stream",
                    value=common_pb2.AnyValue(string_value=log_stream),
                ),
            ],
        )
        extra_attrs = _extract_log_line_attributes(message, log_group)
        if extra_attrs:
            record.attributes.extend(extra_attrs)
        log_records.append(record)

    scope_logs = logs_pb2.ScopeLogs(
        scope=common_pb2.InstrumentationScope(
            name="otel_cw_logs_python",
        ),
        log_records=log_records,
    )

    resource_logs = logs_pb2.ResourceLogs(
        resource=resource,
        scope_logs=[scope_logs],
    )

    return logs_service_pb2.ExportLogsServiceRequest(
        resource_logs=[resource_logs],
    )


def _log_partial_success(
    response: logs_service_pb2.ExportLogsServiceResponse,
) -> None:
    partial = response.partial_success
    if partial.rejected_log_records:
        logger.warning(
            f"OTLP endpoint rejected {partial.rejected_log_records} log records: {partial.error_message}"
        )


def _export_grpc(
    request: logs_service_pb2.ExportLogsServiceRequest, timeout: float, auth_token: str
) -> None:
    metadata = [("authorization", f"Bearer {auth_token}")]
    response = get_stub().Export(
        request,
        timeout=timeout,
        metadata=metadata,
        compression=grpc.Compression.Gzip,
    )
    _log_partial_success(response)


def http_logs_url() -> str:
    """Build the http/protobuf logs URL from OTLP_ENDPOINT, appending the
    standard /v1/logs path unless the endpoint already includes it."""
    target, use_tls = parse_endpoint(OTLP_ENDPOINT)
    scheme = "https" if use_tls else "http"
    url = f"{scheme}://{target.rstrip('/')}"
    if not url.endswith("/v1/logs"):
        url = f"{url}/v1/logs"
    return url


def _export_http(
    request: logs_service_pb2.ExportLogsServiceRequest, timeout: float, auth_token: str
) -> None:
    body = gzip.compress(request.SerializeToString())
    headers = {
        "Content-Type": "application/x-protobuf",
        "Content-Encoding": "gzip",
        "Authorization": f"Bearer {auth_token}",
    }
    headers["Authorization"] = f"Bearer {auth_token}"
    http_request = urllib.request.Request(
        http_logs_url(), data=body, headers=headers, method="POST"
    )

    payload = b""
    for attempt in range(1, HTTP_RETRY_ATTEMPTS + 1):
        try:
            with urllib.request.urlopen(http_request, timeout=timeout) as http_response:
                payload = http_response.read()
            break
        except urllib.error.HTTPError as e:
            if attempt == HTTP_RETRY_ATTEMPTS or e.code not in HTTP_RETRYABLE_STATUSES:
                raise
            logger.warning(
                f"OTLP http export got status {e.code}, retrying (attempt {attempt})"
            )
        except urllib.error.URLError as e:
            if attempt == HTTP_RETRY_ATTEMPTS:
                raise
            logger.warning(
                f"OTLP http export failed ({e.reason}), retrying (attempt {attempt})"
            )
        time.sleep(HTTP_RETRY_BACKOFF_SECONDS * (2 ** (attempt - 1)))

    if payload:
        try:
            response = logs_service_pb2.ExportLogsServiceResponse()
            response.ParseFromString(payload)
            _log_partial_success(response)
        except Exception:
            logger.warning("Could not parse OTLP http export response")


def send_to_otlp(
    request: logs_service_pb2.ExportLogsServiceRequest,
    timeout: float = DEFAULT_EXPORT_TIMEOUT_SECONDS,
    auth_token: str = "",
) -> bool:
    if not OTLP_ENDPOINT:
        logger.error("OTLP_ENDPOINT not configured")
        return False

    export = _export_http if OTLP_PROTOCOL == "http/protobuf" else _export_grpc
    selected_token = auth_token.strip() if auth_token else _default_auth_token()

    try:
        export(request, timeout, selected_token)
        return True
    except grpc.RpcError as e:
        logger.error(f"gRPC error sending logs: {e.code()} - {e.details()}")
        return False
    except urllib.error.URLError as e:
        logger.error(f"HTTP error sending logs: {e}")
        return False
    except Exception:
        logger.exception("Error sending logs to OTLP endpoint")
        return False


# ---------------------------------------------------------------------------
# Forwarder instrumentation — best-effort operational metrics
# ---------------------------------------------------------------------------

LAMBDA_FUNCTION_NAME = os.environ.get(
    "AWS_LAMBDA_FUNCTION_NAME", "otel-cw-logs-forwarder"
)


def _build_forwarder_metrics_request(
    records_processed: int,
    records_failed: int,
    export_duration_ms: float,
) -> metrics_service_pb2.ExportMetricsServiceRequest:
    """Build an OTLP metrics request with operational zs."""
    now_ns = int(time.time() * 1e9)

    resource = resource_pb2.Resource(
        attributes=[
            common_pb2.KeyValue(
                key="service.name",
                value=common_pb2.AnyValue(string_value=LAMBDA_FUNCTION_NAME),
            ),
            common_pb2.KeyValue(
                key="cloud.provider",
                value=common_pb2.AnyValue(string_value="aws"),
            ),
            common_pb2.KeyValue(
                key="cloud.region",
                value=common_pb2.AnyValue(string_value=AWS_REGION),
            ),
        ]
    )
    _set_resource_attributes(resource)

    def _int_dp(value: int) -> metrics_pb2.NumberDataPoint:
        return metrics_pb2.NumberDataPoint(time_unix_nano=now_ns, as_int=value)

    def _double_dp(value: float) -> metrics_pb2.NumberDataPoint:
        return metrics_pb2.NumberDataPoint(time_unix_nano=now_ns, as_double=value)

    metrics = [
        metrics_pb2.Metric(
            name="forwarder.records.processed",
            unit="{records}",
            gauge=metrics_pb2.Gauge(data_points=[_int_dp(records_processed)]),
        ),
        metrics_pb2.Metric(
            name="forwarder.records.failed",
            unit="{records}",
            gauge=metrics_pb2.Gauge(data_points=[_int_dp(records_failed)]),
        ),
        metrics_pb2.Metric(
            name="forwarder.export.duration",
            unit="ms",
            gauge=metrics_pb2.Gauge(data_points=[_double_dp(export_duration_ms)]),
        ),
    ]

    return metrics_service_pb2.ExportMetricsServiceRequest(
        resource_metrics=[
            metrics_pb2.ResourceMetrics(
                resource=resource,
                scope_metrics=[
                    metrics_pb2.ScopeMetrics(
                        scope=common_pb2.InstrumentationScope(
                            name="otel_cw_logs_python",
                        ),
                        metrics=metrics,
                    )
                ],
            )
        ]
    )


def http_metrics_url() -> str:
    """Build the http/protobuf metrics URL from OTLP_ENDPOINT."""
    target, use_tls = parse_endpoint(OTLP_ENDPOINT)
    scheme = "https" if use_tls else "http"
    url = f"{scheme}://{target.rstrip('/')}"
    if not url.endswith("/v1/metrics"):
        url = f"{url}/v1/metrics"
    return url


def emit_forwarder_metrics(
    records_processed: int,
    records_failed: int,
    export_duration_ms: float,
    timeout: float = 5.0,
) -> None:
    """Send operational metrics best-effort. Failures are logged but never
    cause the handler to fail."""
    if not OTLP_ENDPOINT:
        return
    timeout = min(timeout, 5.0)
    if timeout <= 0:
        return
    try:
        request = _build_forwarder_metrics_request(
            records_processed, records_failed, export_duration_ms
        )
        if OTLP_PROTOCOL == "http/protobuf":
            _emit_metrics_http(request, timeout)
        else:
            _emit_metrics_grpc(request, timeout)
    except Exception:
        logger.warning("Failed to send forwarder metrics", exc_info=True)


def _emit_metrics_grpc(
    request: metrics_service_pb2.ExportMetricsServiceRequest, timeout: float
) -> None:
    default_token = _default_auth_token()
    md: list[tuple[str, str]] = [("authorization", f"Bearer {default_token}")]
    _get_metrics_stub().Export(
        request, timeout=timeout, metadata=md, compression=grpc.Compression.Gzip
    )


def _emit_metrics_http(
    request: metrics_service_pb2.ExportMetricsServiceRequest, timeout: float
) -> None:
    body = gzip.compress(request.SerializeToString())
    headers = {
        "Content-Type": "application/x-protobuf",
        "Content-Encoding": "gzip",
    }
    default_token = _default_auth_token()
    headers["Authorization"] = f"Bearer {default_token}"
    http_request = urllib.request.Request(
        http_metrics_url(), data=body, headers=headers, method="POST"
    )
    with urllib.request.urlopen(http_request, timeout=timeout) as resp:
        resp.read()


def remaining_timeout(context: Any) -> float:
    """Cap the per-call timeout so we fail fast instead of dying at the Lambda deadline."""
    if context is not None and hasattr(context, "get_remaining_time_in_millis"):
        remaining_millis = float(context.get_remaining_time_in_millis())
        remaining = remaining_millis / 1000.0 - DEADLINE_SAFETY_MARGIN_SECONDS
        return min(DEFAULT_EXPORT_TIMEOUT_SECONDS, remaining)
    return DEFAULT_EXPORT_TIMEOUT_SECONDS


# AWS_REGION is set automatically in the Lambda runtime environment
AWS_REGION = os.environ.get(
    "AWS_REGION", os.environ.get("AWS_DEFAULT_REGION", "eu-west-2")
)


def sanitize_for_log(value: Any) -> str:
    """Keep bounded allowlisted characters for logging, or mark empty results invalid."""
    if not isinstance(value, str):
        return "<invalid>"
    sanitized = "".join(SANITIZE_FOR_LOG_REGEX.findall(value))[:128]
    return sanitized or "<invalid>"


def _process_cw_logs_payload(payload: dict[str, Any], timeout: float) -> bool:
    """Process a single decoded CloudWatch Logs payload: build the OTLP request and send it.

    Returns True on success (including control messages that are intentionally skipped).
    """
    if payload.get("messageType") == "CONTROL_MESSAGE":
        logger.info("Received control message, skipping")
        return True

    _rate_limiter.wait()
    request = build_export_request(payload, AWS_REGION)
    token_batches = _split_request_by_auth_token(request, payload["logGroup"])
    success = True
    for auth_token, batch_request in token_batches.items():
        if not send_to_otlp(batch_request, timeout, auth_token):
            success = False

    if success:
        log_count = sum(
            len(sl.log_records) for rl in request.resource_logs for sl in rl.scope_logs
        )
        safe_log_group = sanitize_for_log(payload["logGroup"])
        logger.info(f"Forwarded {log_count} log records from {safe_log_group}")
    return success


def _handle_firehose(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """Handle a Kinesis Firehose transform event.

    Each Firehose record contains a base64-encoded, gzip-compressed CloudWatch
    Logs JSON payload.  Successfully forwarded records are returned as
    ``Dropped`` (so Firehose does not persist them to S3); failures are
    ``ProcessingFailed`` (landing in the S3 sink bucket for inspection)."""
    output_records: list[dict[str, str]] = []
    records_processed = 0
    records_failed = 0
    export_duration_ms = 0.0

    for record in event.get("records", []):
        record_id: str = record["recordId"]
        safe_record_id = sanitize_for_log(record_id)
        try:
            timeout = remaining_timeout(context)
            if timeout <= 0:
                logger.error(
                    f"Lambda deadline too close, failing record {safe_record_id} without sending"
                )
                output_records.append(
                    {
                        "recordId": record_id,
                        "result": "ProcessingFailed",
                        "data": record["data"],
                    }
                )
                records_processed += 1
                records_failed += 1
                continue

            compressed = base64.b64decode(record["data"])
            payload = json.loads(gzip.decompress(compressed))
            start = time.monotonic()
            success = _process_cw_logs_payload(payload, timeout)
            export_duration_ms += (time.monotonic() - start) * 1000

            records_processed += 1
            if not success:
                records_failed += 1

            output_records.append(
                {
                    "recordId": record_id,
                    "result": "Dropped" if success else "ProcessingFailed",
                    "data": record["data"],
                }
            )
        except Exception:
            logger.exception(f"Error processing record {safe_record_id}")
            records_processed += 1
            records_failed += 1
            output_records.append(
                {
                    "recordId": record_id,
                    "result": "ProcessingFailed",
                    "data": record["data"],
                }
            )

    emit_forwarder_metrics(
        records_processed,
        records_failed,
        export_duration_ms,
        timeout=remaining_timeout(context),
    )
    return {"records": output_records}


def _handle_cw_logs(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """Handle a direct CloudWatch Logs subscription filter event."""
    try:
        timeout = remaining_timeout(context)
        if timeout <= 0:
            logger.error("Lambda deadline too close, failing without sending")
            return {"status": "error", "error": "deadline too close"}

        payload = decode_cw_logs_event(event)
        start = time.monotonic()
        success = _process_cw_logs_payload(payload, timeout)
        export_duration_ms = (time.monotonic() - start) * 1000

        emit_forwarder_metrics(
            1,
            0 if success else 1,
            export_duration_ms,
            timeout=remaining_timeout(context),
        )

        if success:
            if payload.get("messageType") == "CONTROL_MESSAGE":
                return {"status": "ok", "message": "control message skipped"}
            request = build_export_request(payload, AWS_REGION)
            log_count = sum(
                len(sl.log_records)
                for rl in request.resource_logs
                for sl in rl.scope_logs
            )
            return {"status": "ok", "logCount": log_count}

        return {"status": "error", "error": "failed to send to OTLP endpoint"}

    except Exception:
        logger.exception("Error processing CloudWatch Logs event")
        return {"status": "error", "error": "processing failed"}


def handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """Lambda handler supporting both invocation patterns.

    - **Firehose transform**: event contains ``records`` — each record holds a
      base64+gzipped CloudWatch Logs payload. The handler returns Firehose
      result records (``Dropped`` / ``ProcessingFailed``).
    - **Direct CW Logs subscription**: event contains ``awslogs.data`` — a
      single base64+gzipped payload.
    """
    if "records" in event:
        return _handle_firehose(event, context)
    return _handle_cw_logs(event, context)
