import base64
import gzip
import json
import os
import re
import time
from types import SimpleNamespace
from typing import Any
from unittest.mock import MagicMock, patch

import pytest
from opentelemetry.proto.collector.logs.v1 import logs_service_pb2

os.environ.setdefault("OTLP_AUTH_TOKEN", "test-default-token")


def make_cw_logs_event(
    log_group: str = "/aws/lambda/my-function",
    log_stream: str = "2024/01/01/[$LATEST]abc123",
    owner: str = "123456789012",
    messages: list[str] | None = None,
    message_type: str = "DATA_MESSAGE",
) -> dict[str, dict[str, str]]:
    """Build a CloudWatch Logs subscription filter event."""
    if messages is None:
        messages = ["hello world", "another log line"]

    log_events = [
        {
            "id": f"event-{i}",
            "timestamp": int(time.time() * 1000) - (i * 1000),
            "message": msg,
        }
        for i, msg in enumerate(messages)
    ]

    payload = {
        "messageType": message_type,
        "owner": owner,
        "logGroup": log_group,
        "logStream": log_stream,
        "subscriptionFilters": ["test-filter"],
        "logEvents": log_events,
    }

    compressed = gzip.compress(json.dumps(payload).encode())
    encoded = base64.b64encode(compressed).decode()
    return {"awslogs": {"data": encoded}}


def test_decode_cw_logs_event():
    """The awslogs payload is base64 + gzip decoded correctly."""
    from otel_cw_logs_python.function import decode_cw_logs_event

    event = make_cw_logs_event(
        log_group="/aws/ecs/my-service",
        messages=["line one", "line two"],
    )
    payload = decode_cw_logs_event(event)

    assert payload["logGroup"] == "/aws/ecs/my-service"
    assert payload["messageType"] == "DATA_MESSAGE"
    assert len(payload["logEvents"]) == 2
    assert payload["logEvents"][0]["message"] == "line one"
    assert payload["logEvents"][1]["message"] == "line two"


def test_build_export_request_sets_service_name():
    """service.name defaults to the CloudWatch log group name."""
    from otel_cw_logs_python.function import build_export_request, decode_cw_logs_event

    event = make_cw_logs_event(log_group="/aws/lambda/my-function")
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    resource_attrs = {
        a.key: a.value.string_value
        for a in request.resource_logs[0].resource.attributes
    }
    assert resource_attrs["service.name"] == "/aws/lambda/my-function"


def test_build_export_request_sets_cloud_attributes():
    """Standard cloud resource attributes are populated."""
    from otel_cw_logs_python.function import build_export_request, decode_cw_logs_event

    event = make_cw_logs_event(owner="999888777666")
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "us-east-1")

    resource_attrs = {
        a.key: a.value.string_value
        for a in request.resource_logs[0].resource.attributes
    }
    assert resource_attrs["cloud.provider"] == "aws"
    assert resource_attrs["cloud.region"] == "us-east-1"
    assert resource_attrs["cloud.account.id"] == "999888777666"


def test_build_export_request_log_records():
    """Each CW log event becomes an OTLP LogRecord with correct body and attributes."""
    from otel_cw_logs_python.function import build_export_request, decode_cw_logs_event

    event = make_cw_logs_event(
        log_group="/aws/lambda/fn",
        log_stream="stream-1",
        messages=["msg-a", "msg-b", "msg-c"],
    )
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    records = request.resource_logs[0].scope_logs[0].log_records
    assert len(records) == 3
    assert records[0].body.string_value == "msg-a"
    assert records[1].body.string_value == "msg-b"
    assert records[2].body.string_value == "msg-c"

    for rec in records:
        attrs = {a.key: a.value.string_value for a in rec.attributes}
        assert attrs["aws.cloudwatch.log_group"] == "/aws/lambda/fn"
        assert attrs["aws.cloudwatch.log_stream"] == "stream-1"
        assert rec.time_unix_nano > 0
        assert rec.observed_time_unix_nano > 0


def test_build_export_request_timestamp_conversion():
    """CW millisecond timestamps are converted to nanoseconds."""
    from otel_cw_logs_python.function import build_export_request, decode_cw_logs_event

    event = make_cw_logs_event(messages=["test"])
    payload = decode_cw_logs_event(event)
    ts_ms = payload["logEvents"][0]["timestamp"]

    request = build_export_request(payload, "eu-west-2")
    record = request.resource_logs[0].scope_logs[0].log_records[0]

    assert record.time_unix_nano == ts_ms * 1_000_000


def test_build_export_request_instrumentation_scope():
    """The instrumentation scope is set to identify this lambda."""
    from otel_cw_logs_python.function import build_export_request, decode_cw_logs_event

    event = make_cw_logs_event()
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    scope = request.resource_logs[0].scope_logs[0].scope
    assert scope.name == "otel_cw_logs_python"


def test_resource_attributes_enrichment(monkeypatch):
    """OTEL_RESOURCE_ATTRIBUTES are merged into the resource."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import (
        _parse_resource_attributes,
        build_export_request,
        decode_cw_logs_event,
    )

    monkeypatch.setattr(
        function,
        "OTEL_RESOURCE_ATTRIBUTES",
        _parse_resource_attributes(
            "deployment.environment.name=production,deployment.environment=prod"
        ),
    )

    event = make_cw_logs_event()
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    resource_attrs = {
        a.key: a.value.string_value
        for a in request.resource_logs[0].resource.attributes
    }
    assert resource_attrs["deployment.environment.name"] == "production"
    assert resource_attrs["deployment.environment"] == "prod"
    # default attributes are still present
    assert resource_attrs["cloud.provider"] == "aws"
    assert "service.name" in resource_attrs


def test_resource_attributes_overwrite_defaults(monkeypatch):
    """OTEL_RESOURCE_ATTRIBUTES can override default resource attributes."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import (
        _parse_resource_attributes,
        build_export_request,
        decode_cw_logs_event,
    )

    monkeypatch.setattr(
        function,
        "OTEL_RESOURCE_ATTRIBUTES",
        _parse_resource_attributes("service.name=custom-service"),
    )

    event = make_cw_logs_event(log_group="/aws/lambda/fn")
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    resource_attrs = {
        a.key: a.value.string_value
        for a in request.resource_logs[0].resource.attributes
    }
    assert resource_attrs["service.name"] == "custom-service"
    # no duplicate
    keys = [a.key for a in request.resource_logs[0].resource.attributes]
    assert keys.count("service.name") == 1


def test_resource_attributes_empty_values_skipped(monkeypatch):
    """Empty values in OTEL_RESOURCE_ATTRIBUTES are not added."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import (
        _parse_resource_attributes,
        build_export_request,
        decode_cw_logs_event,
    )

    monkeypatch.setattr(
        function,
        "OTEL_RESOURCE_ATTRIBUTES",
        _parse_resource_attributes("deployment.environment.name=,valid=yes"),
    )

    event = make_cw_logs_event()
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    keys = [a.key for a in request.resource_logs[0].resource.attributes]
    assert "deployment.environment.name" not in keys
    resource_attrs = {
        a.key: a.value.string_value
        for a in request.resource_logs[0].resource.attributes
    }
    assert resource_attrs["valid"] == "yes"


def test_parse_auth_token_map_from_single_token():
    """OTLP_AUTH_TOKEN is mapped to the default named token."""
    from otel_cw_logs_python.function import _parse_auth_token_map

    assert _parse_auth_token_map("sekret", "") == {"default": "sekret"}


def test_parse_auth_token_map_mutually_exclusive_raises():
    """OTLP_AUTH_TOKEN and OTLP_AUTH_TOKEN_MAP cannot be set together."""
    from otel_cw_logs_python.function import _parse_auth_token_map

    with pytest.raises(
        ValueError, match="Set either OTLP_AUTH_TOKEN or OTLP_AUTH_TOKEN_MAP, not both"
    ):
        _parse_auth_token_map("sekret", '{"default":"another"}')


def test_parse_auth_token_map_requires_default_when_mapped():
    """OTLP_AUTH_TOKEN_MAP must include a non-empty default token."""
    from otel_cw_logs_python.function import _parse_auth_token_map

    with pytest.raises(
        ValueError,
        match="OTLP_AUTH_TOKEN_MAP must include a non-empty 'default' token",
    ):
        _parse_auth_token_map("", '{"pid":"token"}')


def test_parse_auth_token_map_requires_configuration():
    """A default auth token config is required at startup."""
    from otel_cw_logs_python.function import _parse_auth_token_map

    with pytest.raises(ValueError, match="Set OTLP_AUTH_TOKEN or OTLP_AUTH_TOKEN_MAP"):
        _parse_auth_token_map("", "")


def test_secret_auth_token_is_cached(monkeypatch):
    import otel_cw_logs_python.function as function

    class SecretsManager:
        calls = 0

        def get_secret_value(self, SecretId):
            self.calls += 1
            return {"SecretString": "runtime-token"}

    client = SecretsManager()
    monkeypatch.setattr(function, "AUTH_TOKEN_MAP", {})
    monkeypatch.setattr(
        function,
        "AUTH_TOKEN_SECRET_ARN_MAP",
        {"default": "arn:aws:secretsmanager:eu-west-2:123456789012:secret:otel-token-abcd"},
    )
    monkeypatch.setattr(function, "_secrets_manager_client", client)
    monkeypatch.setattr(function, "_secret_cache", {})

    assert function._default_auth_token() == "runtime-token"
    assert function._default_auth_token() == "runtime-token"
    assert client.calls == 1


@pytest.mark.parametrize("secret_response", [{}, {"SecretString": None}, {"SecretString": "  "}])
def test_secret_auth_token_rejects_missing_or_empty_value(monkeypatch, secret_response):
    import otel_cw_logs_python.function as function

    class SecretsManager:
        def get_secret_value(self, SecretId):
            return secret_response

    monkeypatch.setattr(function, "AUTH_TOKEN_MAP", {})
    monkeypatch.setattr(
        function,
        "AUTH_TOKEN_SECRET_ARN_MAP",
        {"default": "arn:aws:secretsmanager:eu-west-2:123456789012:secret:otel-token-abcd"},
    )
    monkeypatch.setattr(function, "_secrets_manager_client", SecretsManager())
    monkeypatch.setattr(function, "_secret_cache", {})

    with pytest.raises(ValueError, match="no non-empty SecretString"):
        function._default_auth_token()


def test_secret_auth_token_propagates_secrets_manager_error(monkeypatch):
    import otel_cw_logs_python.function as function

    class SecretsManager:
        def get_secret_value(self, SecretId):
            raise RuntimeError("Secrets Manager unavailable")

    monkeypatch.setattr(function, "AUTH_TOKEN_MAP", {})
    monkeypatch.setattr(
        function,
        "AUTH_TOKEN_SECRET_ARN_MAP",
        {"default": "arn:aws:secretsmanager:eu-west-2:123456789012:secret:otel-token-abcd"},
    )
    monkeypatch.setattr(function, "_secrets_manager_client", SecretsManager())
    monkeypatch.setattr(function, "_secret_cache", {})

    with pytest.raises(RuntimeError, match="Secrets Manager unavailable"):
        function._default_auth_token()


def test_resolve_auth_token_for_log_record_uses_log_group_selectors(monkeypatch):
    """Selectors resolve named auth tokens with exact and regex matching."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import (
        LogGroupAuthTokenMapping,
        LogGroupSelector,
        _resolve_auth_token_for_log_record,
    )

    monkeypatch.setattr(
        function,
        "AUTH_TOKEN_MAP",
        {"default": "default-token", "lambda": "lambda-token", "ecs": "ecs-token"},
    )
    monkeypatch.setattr(
        function,
        "LOG_GROUP_AUTH_TOKEN_MAPPINGS",
        [
            LogGroupAuthTokenMapping(
                token_name="lambda",
                selector=LogGroupSelector(re.compile(r"^/aws/lambda/")),
            ),
            LogGroupAuthTokenMapping(
                token_name="ecs",
                selector=LogGroupSelector(re.compile(r"^/aws/ecs/task$")),
            ),
        ],
    )
    monkeypatch.setattr(function, "ATTRIBUTE_AUTH_TOKEN_MAPPINGS", [])

    assert (
        _resolve_auth_token_for_log_record("/aws/lambda/my-fn", {}, {})
        == "lambda-token"
    )
    assert _resolve_auth_token_for_log_record("/aws/ecs/task", {}, {}) == "ecs-token"
    assert _resolve_auth_token_for_log_record("/other/group", {}, {}) == "default-token"


def test_parse_log_group_auth_token_mappings():
    """LOG_GROUP_AUTH_TOKEN_MAP parses selector keys and token-name values."""
    from otel_cw_logs_python.function import _parse_log_group_auth_token_mappings

    mappings = _parse_log_group_auth_token_mappings(
        '{"^/aws/lambda/.*": "lambda", "/aws/ecs/task": "ecs"}'
    )
    assert len(mappings) == 2
    assert mappings[0].matches_log_group("/aws/lambda/fn")
    assert not mappings[0].matches_log_group("/aws/ecs/task")
    assert mappings[0].token_name == "lambda"
    assert mappings[1].matches_log_group("/aws/ecs/task")
    assert mappings[1].token_name == "ecs"
    assert not mappings[1].matches_log_group("prefix/aws/ecs/task")


def test_parse_log_group_resource_attribute_mappings_normalizes_slash_prefix():
    """A '/'-prefixed selector is pinned to start-of-string for resource mapping."""
    from otel_cw_logs_python.function import (
        _parse_log_group_resource_attribute_mappings,
    )

    mappings = _parse_log_group_resource_attribute_mappings(
        '{"/aws/lambda/platform-api":"service.name=platform"}'
    )
    assert len(mappings) == 1
    assert mappings[0].matches_log_group("/aws/lambda/platform-api")
    assert not mappings[0].matches_log_group("prefix/aws/lambda/platform-api")


def test_parse_attribute_auth_token_mappings():
    """Resource attribute auth token map parses key=regex selectors."""
    from otel_cw_logs_python.function import (
        _parse_attribute_auth_token_mappings,
    )

    mappings = _parse_attribute_auth_token_mappings(
        '{"deployment.environment.name=.*-prod":"prod"}'
    )
    assert len(mappings) == 1
    assert mappings[0].matches_attributes({"deployment.environment.name": "pid-prod"})
    assert not mappings[0].matches_attributes(
        {"deployment.environment.name": "pid-dev"}
    )
    assert mappings[0].token_name == "prod"


def test_validate_log_group_auth_token_mappings_rejects_unknown_token_names():
    """All LOG_GROUP_AUTH_TOKEN_MAP values must exist in OTLP_AUTH_TOKEN_MAP."""
    from otel_cw_logs_python.function import (
        LogGroupAuthTokenMapping,
        LogGroupSelector,
        _validate_log_group_auth_token_mappings,
    )

    mappings = [
        LogGroupAuthTokenMapping(
            token_name="missing",
            selector=LogGroupSelector(re.compile(r"^/aws/lambda/")),
        )
    ]
    with pytest.raises(
        ValueError, match="LOG_GROUP_AUTH_TOKEN_MAP references unknown auth token names"
    ):
        _validate_log_group_auth_token_mappings(mappings, {"default": "default-token"})


def test_validate_attribute_auth_token_mappings_rejects_unknown_token_names():
    """Resource attribute auth token mappings must reference known token names."""
    from otel_cw_logs_python.function import (
        AttributeAuthTokenMapping,
        _validate_attribute_auth_token_mappings,
    )

    mappings = [
        AttributeAuthTokenMapping(
            attr_key="deployment.environment.name",
            value_pattern=re.compile(r".*-prod"),
            token_name="missing",
        )
    ]
    with pytest.raises(
        ValueError,
        match="OTEL_ATTRIBUTE_AUTH_TOKEN_MAP references unknown auth token names",
    ):
        _validate_attribute_auth_token_mappings(
            mappings, {"default": "default-token", "prod": "prod-token"}
        )


def test_resolve_auth_token_for_log_record_matches_resource_attributes(monkeypatch):
    """Attribute mappings match against resource attributes."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import (
        AttributeAuthTokenMapping,
        _resolve_auth_token_for_log_record,
    )

    monkeypatch.setattr(
        function,
        "AUTH_TOKEN_MAP",
        {"default": "default-token", "prod": "prod-token"},
    )
    monkeypatch.setattr(function, "LOG_GROUP_AUTH_TOKEN_MAPPINGS", [])
    monkeypatch.setattr(
        function,
        "ATTRIBUTE_AUTH_TOKEN_MAPPINGS",
        [
            AttributeAuthTokenMapping(
                attr_key="deployment.environment.name",
                value_pattern=re.compile(r".*-prod"),
                token_name="prod",
            )
        ],
    )

    token = _resolve_auth_token_for_log_record(
        "/aws/lambda/pid-api",
        {"deployment.environment.name": "pid-prod"},
        {},
    )
    assert token == "prod-token"


def test_resolve_auth_token_for_log_record_matches_record_attributes(monkeypatch):
    """Attribute mappings also match against per-record attributes."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import (
        AttributeAuthTokenMapping,
        _resolve_auth_token_for_log_record,
    )

    monkeypatch.setattr(
        function,
        "AUTH_TOKEN_MAP",
        {"default": "default-token", "prod": "prod-token"},
    )
    monkeypatch.setattr(function, "LOG_GROUP_AUTH_TOKEN_MAPPINGS", [])
    monkeypatch.setattr(
        function,
        "ATTRIBUTE_AUTH_TOKEN_MAPPINGS",
        [
            AttributeAuthTokenMapping(
                attr_key="deployment.environment.name",
                value_pattern=re.compile(r".*-prod"),
                token_name="prod",
            )
        ],
    )

    token = _resolve_auth_token_for_log_record(
        "/aws/lambda/pid-api",
        {},
        {"deployment.environment.name": "pid-prod"},
    )
    assert token == "prod-token"


def test_resolve_auth_token_for_log_record_prefers_record_attributes(monkeypatch):
    """Record attributes override resource attributes on key conflicts."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import (
        AttributeAuthTokenMapping,
        LogGroupAuthTokenMapping,
        LogGroupSelector,
        _resolve_auth_token_for_log_record,
    )

    monkeypatch.setattr(
        function,
        "AUTH_TOKEN_MAP",
        {
            "default": "default-token",
            "pid": "pid-token",
            "prod": "prod-token",
        },
    )
    monkeypatch.setattr(
        function,
        "LOG_GROUP_AUTH_TOKEN_MAPPINGS",
        [
            LogGroupAuthTokenMapping(
                token_name="pid",
                selector=LogGroupSelector(re.compile(r"^/aws/lambda/pid-")),
            )
        ],
    )
    monkeypatch.setattr(
        function,
        "ATTRIBUTE_AUTH_TOKEN_MAPPINGS",
        [
            AttributeAuthTokenMapping(
                attr_key="deployment.environment.name",
                value_pattern=re.compile(r".*-prod"),
                token_name="prod",
            )
        ],
    )

    token = _resolve_auth_token_for_log_record(
        "/aws/lambda/pid-api",
        {"deployment.environment.name": "pid-dev"},
        {"deployment.environment.name": "pid-prod"},
    )
    assert token == "prod-token"


def test_split_request_by_auth_token_groups_records(monkeypatch):
    """Records with different merged attributes are sent in separate batches."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import (
        AttributeAuthTokenMapping,
        _split_request_by_auth_token,
        build_export_request,
    )

    monkeypatch.setattr(
        function,
        "AUTH_TOKEN_MAP",
        {
            "default": "default-token",
            "prod": "prod-token",
            "dev": "dev-token",
        },
    )
    monkeypatch.setattr(function, "LOG_GROUP_AUTH_TOKEN_MAPPINGS", [])
    monkeypatch.setattr(
        function,
        "ATTRIBUTE_AUTH_TOKEN_MAPPINGS",
        [
            AttributeAuthTokenMapping(
                attr_key="deployment.environment.name",
                value_pattern=re.compile(r".*-prod"),
                token_name="prod",
            ),
            AttributeAuthTokenMapping(
                attr_key="deployment.environment.name",
                value_pattern=re.compile(r".*-dev"),
                token_name="dev",
            ),
        ],
    )
    monkeypatch.setattr(
        function,
        "LOG_LINE_REGEX_MAPPINGS",
        [
            function.RegexMapping(
                re.compile(
                    r"env=(?P<deployment__environment__name>tenant-(?:prod|dev))"
                )
            )
        ],
    )

    payload: dict[str, Any] = {
        "messageType": "DATA_MESSAGE",
        "owner": "123456789012",
        "logGroup": "/aws/lambda/pid-api",
        "logStream": "2024/01/01/[$LATEST]abc123",
        "subscriptionFilters": ["test-filter"],
        "logEvents": [
            {
                "id": "event-0",
                "timestamp": 1_700_000_000_000,
                "message": "env=tenant-prod",
            },
            {
                "id": "event-1",
                "timestamp": 1_700_000_001_000,
                "message": "env=tenant-dev",
            },
        ],
    }

    request = build_export_request(payload, "eu-west-2")
    batches = _split_request_by_auth_token(request, payload["logGroup"])

    assert set(batches) == {"prod-token", "dev-token"}
    assert [
        record.body.string_value
        for record in batches["prod-token"].resource_logs[0].scope_logs[0].log_records
    ] == ["env=tenant-prod"]
    assert [
        record.body.string_value
        for record in batches["dev-token"].resource_logs[0].scope_logs[0].log_records
    ] == ["env=tenant-dev"]


def test_handler_selects_auth_token_by_log_group(monkeypatch):
    """Handler chooses auth tokens per record log group selectors."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import (
        LogGroupAuthTokenMapping,
        LogGroupSelector,
        handler,
    )

    monkeypatch.setattr(
        function,
        "AUTH_TOKEN_MAP",
        {"default": "default-token", "lambda": "lambda-token"},
    )
    monkeypatch.setattr(
        function,
        "LOG_GROUP_AUTH_TOKEN_MAPPINGS",
        [
            LogGroupAuthTokenMapping(
                token_name="lambda",
                selector=LogGroupSelector(re.compile(r"^/aws/lambda/")),
            )
        ],
    )

    event = {
        "records": [
            make_firehose_record(record_id="r1", log_group="/aws/lambda/fn"),
            make_firehose_record(record_id="r2", log_group="/aws/ecs/task"),
        ]
    }

    with patch("otel_cw_logs_python.function.send_to_otlp") as mock_send:
        mock_send.return_value = True
        result = handler(event, None)

    assert len(result["records"]) == 2
    assert mock_send.call_count == 2
    assert mock_send.call_args_list[0][0][2] == "lambda-token"
    assert mock_send.call_args_list[1][0][2] == "default-token"


def test_log_group_resource_attribute_overrides_exact_match(monkeypatch):
    """Exact log-group mapping overrides global attributes for matching groups."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import (
        ResourceAttributeMapping,
        _parse_resource_attributes,
        build_export_request,
        decode_cw_logs_event,
    )

    monkeypatch.setattr(
        function,
        "OTEL_RESOURCE_ATTRIBUTES",
        _parse_resource_attributes(
            "service.name=global-svc,deployment.environment=prod"
        ),
    )
    monkeypatch.setattr(
        function,
        "LOG_GROUP_RESOURCE_ATTRIBUTE_MAPPINGS",
        [
            ResourceAttributeMapping(
                attrs=_parse_resource_attributes(
                    "service.name=group-svc,deployment.environment.name=staging"
                ),
                selector=function.LogGroupSelector(
                    re.compile(r"^/aws/lambda/my-function$")
                ),
            )
        ],
    )

    event = make_cw_logs_event(log_group="/aws/lambda/my-function")
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    attrs = resource_attrs_dict(request)
    assert attrs["service.name"] == "group-svc"
    assert attrs["deployment.environment"] == "prod"
    assert attrs["deployment.environment.name"] == "staging"


def test_log_group_resource_attribute_overrides_regex_match(monkeypatch):
    """Regex log-group mapping applies to matching groups."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import (
        ResourceAttributeMapping,
        _parse_resource_attributes,
        build_export_request,
        decode_cw_logs_event,
    )

    monkeypatch.setattr(
        function,
        "OTEL_RESOURCE_ATTRIBUTES",
        _parse_resource_attributes("service.name=global-svc"),
    )
    monkeypatch.setattr(
        function,
        "LOG_GROUP_RESOURCE_ATTRIBUTE_MAPPINGS",
        [
            ResourceAttributeMapping(
                attrs=_parse_resource_attributes("service.name=lambda-svc"),
                selector=function.LogGroupSelector(re.compile(r"^/aws/lambda/")),
            )
        ],
    )

    event = make_cw_logs_event(log_group="/aws/lambda/some-fn")
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    assert resource_attrs_dict(request)["service.name"] == "lambda-svc"


def test_log_group_resource_attribute_overrides_no_match(monkeypatch):
    """When no mapping matches, global attributes remain unchanged."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import (
        ResourceAttributeMapping,
        _parse_resource_attributes,
        build_export_request,
        decode_cw_logs_event,
    )

    monkeypatch.setattr(
        function,
        "OTEL_RESOURCE_ATTRIBUTES",
        _parse_resource_attributes("service.name=global-svc"),
    )
    monkeypatch.setattr(
        function,
        "LOG_GROUP_RESOURCE_ATTRIBUTE_MAPPINGS",
        [
            ResourceAttributeMapping(
                attrs=_parse_resource_attributes("service.name=ecs-svc"),
                selector=function.LogGroupSelector(re.compile(r"^/aws/ecs/")),
            )
        ],
    )

    event = make_cw_logs_event(log_group="/aws/lambda/some-fn")
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    assert resource_attrs_dict(request)["service.name"] == "global-svc"


def test_handler_success(monkeypatch):
    """A successful export returns status ok with the log count."""
    from otel_cw_logs_python.function import handler

    event = make_cw_logs_event(messages=["line1", "line2", "line3"])

    with patch("otel_cw_logs_python.function.send_to_otlp") as mock_send:
        mock_send.return_value = True
        result = handler(event, None)

    assert result["status"] == "ok"
    assert result["logCount"] == 3
    mock_send.assert_called_once()


def test_handler_send_failure():
    """A failed export returns status error."""
    from otel_cw_logs_python.function import handler

    event = make_cw_logs_event()

    with patch("otel_cw_logs_python.function.send_to_otlp") as mock_send:
        mock_send.return_value = False
        result = handler(event, None)

    assert result["status"] == "error"


def test_handler_control_message():
    """Control messages are skipped without calling the endpoint."""
    from otel_cw_logs_python.function import handler

    event = make_cw_logs_event(message_type="CONTROL_MESSAGE")

    with patch("otel_cw_logs_python.function.send_to_otlp") as mock_send:
        result = handler(event, None)

    assert result["status"] == "ok"
    assert "control" in result["message"]
    mock_send.assert_not_called()


def test_handler_fails_fast_when_deadline_close():
    """When the Lambda deadline is nearly reached, the handler fails without sending."""
    from otel_cw_logs_python.function import handler

    context = SimpleNamespace(get_remaining_time_in_millis=lambda: 1000)
    event = make_cw_logs_event()

    with patch("otel_cw_logs_python.function.send_to_otlp") as mock_send:
        result = handler(event, context)

    assert result["status"] == "error"
    mock_send.assert_not_called()


def test_handler_passes_capped_timeout():
    """The per-call timeout is capped by the remaining Lambda time."""
    from otel_cw_logs_python.function import handler

    context = SimpleNamespace(get_remaining_time_in_millis=lambda: 80_000)
    event = make_cw_logs_event()

    with patch("otel_cw_logs_python.function.send_to_otlp") as mock_send:
        mock_send.return_value = True
        handler(event, context)

    timeout = mock_send.call_args[0][1]
    assert timeout == pytest.approx(60.0)


@pytest.mark.parametrize(
    ("endpoint", "expected_target", "expected_tls"),
    [
        ("https://collector.example.com:4317", "collector.example.com:4317", True),
        ("grpcs://collector.example.com:4317", "collector.example.com:4317", True),
        ("http://collector.example.com:4317", "collector.example.com:4317", False),
        ("grpc://collector.example.com:4317", "collector.example.com:4317", False),
        ("collector.example.com:4317", "collector.example.com:4317", True),
    ],
)
def test_parse_endpoint(endpoint, expected_target, expected_tls):
    """Endpoint schemes map to the right target and TLS setting."""
    from otel_cw_logs_python.function import parse_endpoint

    target, use_tls = parse_endpoint(endpoint)
    assert target == expected_target
    assert use_tls is expected_tls


@pytest.mark.parametrize(
    ("endpoint", "expected_url"),
    [
        (
            "https://collector.example.com:4318",
            "https://collector.example.com:4318/v1/logs",
        ),
        (
            "http://collector.example.com:4318",
            "http://collector.example.com:4318/v1/logs",
        ),
        (
            "grpcs://collector.example.com:4318",
            "https://collector.example.com:4318/v1/logs",
        ),
        ("collector.example.com:4318", "https://collector.example.com:4318/v1/logs"),
        (
            "https://collector.example.com/otlp",
            "https://collector.example.com/otlp/v1/logs",
        ),
        (
            "https://collector.example.com/v1/logs",
            "https://collector.example.com/v1/logs",
        ),
    ],
)
def test_http_logs_url(monkeypatch, endpoint, expected_url):
    """The http/protobuf URL gets /v1/logs appended unless already present."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import http_logs_url

    monkeypatch.setattr(function, "OTLP_ENDPOINT", endpoint)
    assert http_logs_url() == expected_url


def _test_http_protobuf_export_legacy(monkeypatch):
    """With OTLP_PROTOCOL=http/protobuf the request is POSTed as gzipped protobuf."""
    import gzip as gzip_mod

    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import (
        build_export_request,
        decode_cw_logs_event,
        send_to_otlp,
    )

    monkeypatch.setattr(function, "OTLP_ENDPOINT", "https://collector.example.com:4318")
    monkeypatch.setattr(function, "OTLP_PROTOCOL", "http/protobuf")
    monkeypatch.setattr(function, "AUTH_TOKEN_MAP", {"default": "sekret"})

    event = make_cw_logs_event(messages=["hello"])
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    response_cm = MagicMock()
    response_cm.__enter__.return_value.read.return_value = b""

    with patch("urllib.request.urlopen", return_value=response_cm) as mock_urlopen:
        assert send_to_otlp(request) is True

        mock_urlopen.assert_called_once()
        http_request = mock_urlopen.call_args[0][0]

        assert http_request.full_url == "https://collector.example.com:4318/v1/logs"
        assert http_request.get_method() == "POST"
        assert http_request.get_header("Content-type") == "application/x-protobuf"
        assert http_request.get_header("Content-encoding") == "gzip"
        assert http_request.get_header("Authorization") == "Bearer sekret"

        sent = logs_service_pb2.ExportLogsServiceRequest()
        sent.ParseFromString(gzip_mod.decompress(http_request.data))
        assert len(sent.resource_logs) == 1


def test_http_protobuf_export(monkeypatch):
    """With OTLP_PROTOCOL=http/protobuf the request is POSTed as gzipped protobuf."""
    import gzip as gzip_mod

    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import (
        build_export_request,
        decode_cw_logs_event,
        send_to_otlp,
    )

    monkeypatch.setattr(function, "OTLP_ENDPOINT", "https://collector.example.com:4318")
    monkeypatch.setattr(function, "OTLP_PROTOCOL", "http/protobuf")
    monkeypatch.setattr(function, "AUTH_TOKEN_MAP", {"default": "sekret"})

    event = make_cw_logs_event(messages=["hello"])
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    response_cm = MagicMock()
    response_cm.__enter__.return_value.read.return_value = b""

    with patch("urllib.request.urlopen", return_value=response_cm) as mock_urlopen:
        assert send_to_otlp(request) is True

        mock_urlopen.assert_called_once()
        http_request = mock_urlopen.call_args[0][0]

        assert http_request.full_url == "https://collector.example.com:4318/v1/logs"
        assert http_request.get_method() == "POST"
        assert http_request.get_header("Content-type") == "application/x-protobuf"
        assert http_request.get_header("Content-encoding") == "gzip"
        assert http_request.get_header("Authorization") == "Bearer sekret"

        sent = logs_service_pb2.ExportLogsServiceRequest()
        sent.ParseFromString(gzip_mod.decompress(http_request.data))
        assert len(sent.resource_logs) == 1


def test_http_protobuf_export_failure_retries(monkeypatch):
    """Persistent HTTP failures are retried then fail."""
    import urllib.error

    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import (
        build_export_request,
        decode_cw_logs_event,
        send_to_otlp,
    )

    monkeypatch.setattr(function, "OTLP_ENDPOINT", "https://collector.example.com:4318")
    monkeypatch.setattr(function, "OTLP_PROTOCOL", "http/protobuf")
    monkeypatch.setattr(function, "HTTP_RETRY_BACKOFF_SECONDS", 0)

    event = make_cw_logs_event(messages=["hello"])
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    with patch(
        "urllib.request.urlopen",
        side_effect=urllib.error.URLError("connection refused"),
    ) as mock_urlopen:
        assert send_to_otlp(request) is False
        assert mock_urlopen.call_count == function.HTTP_RETRY_ATTEMPTS


def test_send_to_otlp_no_endpoint(monkeypatch):
    """When OTLP_ENDPOINT is not set, send_to_otlp returns False."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import (
        build_export_request,
        decode_cw_logs_event,
        send_to_otlp,
    )

    monkeypatch.setattr(function, "OTLP_ENDPOINT", "")

    event = make_cw_logs_event(messages=["hello"])
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    assert send_to_otlp(request) is False


def test_handler_exception_returns_error():
    """An unexpected exception in the handler returns an error response."""
    from otel_cw_logs_python.function import handler

    # missing awslogs key will cause a KeyError
    result = handler({}, None)
    assert result["status"] == "error"


@pytest.mark.parametrize(
    ("group_name", "expected_key"),
    [
        ("service__name", "service.name"),
        ("deployment__environment__name", "deployment.environment.name"),
        ("simple", "simple"),
        ("cloud__account__id", "cloud.account.id"),
        ("no_dots_here", "no_dots_here"),
    ],
)
def test_group_name_to_attr_key(group_name, expected_key):
    """Double underscores in regex group names map to dots in attribute keys."""
    from otel_cw_logs_python.function import _group_name_to_attr_key

    assert _group_name_to_attr_key(group_name) == expected_key


def test_log_group_regex_extracts_service_name(monkeypatch):
    """LOG_GROUP_REGEX named groups are extracted as resource attributes."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import build_export_request, decode_cw_logs_event

    monkeypatch.setattr(
        function,
        "LOG_GROUP_REGEX",
        re.compile(r"^/aws/lambda/(?P<service__name>.+)$"),
    )

    event = make_cw_logs_event(log_group="/aws/lambda/my-cool-service")
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    resource_attrs = {
        a.key: a.value.string_value
        for a in request.resource_logs[0].resource.attributes
    }
    assert resource_attrs["service.name"] == "my-cool-service"
    # cloud attributes are still present
    assert resource_attrs["cloud.provider"] == "aws"


def test_log_group_regex_extracts_multiple_attributes(monkeypatch):
    """Multiple named groups are all extracted as resource attributes."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import build_export_request, decode_cw_logs_event

    monkeypatch.setattr(
        function,
        "LOG_GROUP_REGEX",
        re.compile(
            r"^/(?P<deployment__environment__name>[^/]+)/(?P<service__name>.+)$"
        ),
    )

    event = make_cw_logs_event(log_group="/prod/payment-api")
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    resource_attrs = {
        a.key: a.value.string_value
        for a in request.resource_logs[0].resource.attributes
    }
    assert resource_attrs["service.name"] == "payment-api"
    assert resource_attrs["deployment.environment.name"] == "prod"


def test_log_group_regex_no_match_keeps_defaults(monkeypatch):
    """When the regex doesn't match, defaults are unchanged."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import build_export_request, decode_cw_logs_event

    monkeypatch.setattr(
        function,
        "LOG_GROUP_REGEX",
        re.compile(r"^/aws/lambda/(?P<service__name>.+)$"),
    )

    event = make_cw_logs_event(log_group="/aws/ecs/some-task")
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    resource_attrs = {
        a.key: a.value.string_value
        for a in request.resource_logs[0].resource.attributes
    }
    # service.name falls back to the full log group
    assert resource_attrs["service.name"] == "/aws/ecs/some-task"


def test_log_group_regex_empty_capture_skipped(monkeypatch):
    """Named groups that capture an empty string are not added."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import build_export_request, decode_cw_logs_event

    monkeypatch.setattr(
        function,
        "LOG_GROUP_REGEX",
        re.compile(
            r"^(?P<service__name>[^/]*)(?:/(?P<deployment__environment__name>.*))?$"
        ),
    )

    event = make_cw_logs_event(log_group="/something")
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    # keys = [a.key for a in request.resource_logs[0].resource.attributes]
    # service__name captured "" (leading slash means first char is /), so skipped
    # deployment.environment.name captured "something"
    assert resource_attrs_dict(request)["deployment.environment.name"] == "something"


def resource_attrs_dict(
    request: logs_service_pb2.ExportLogsServiceRequest,
) -> dict[str, str]:
    return {
        a.key: a.value.string_value
        for a in request.resource_logs[0].resource.attributes
    }


def test_log_group_regex_otel_resource_attrs_take_precedence(monkeypatch):
    """OTEL_RESOURCE_ATTRIBUTES override LOG_GROUP_REGEX extractions."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import (
        _parse_resource_attributes,
        build_export_request,
        decode_cw_logs_event,
    )

    monkeypatch.setattr(
        function,
        "LOG_GROUP_REGEX",
        re.compile(r"^/aws/lambda/(?P<service__name>.+)$"),
    )
    monkeypatch.setattr(
        function,
        "OTEL_RESOURCE_ATTRIBUTES",
        _parse_resource_attributes("service.name=override-svc"),
    )

    event = make_cw_logs_event(log_group="/aws/lambda/extracted-name")
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    attrs = resource_attrs_dict(request)
    # OTEL_RESOURCE_ATTRIBUTES wins over the regex extraction
    assert attrs["service.name"] == "override-svc"
    # no duplicates
    keys = [a.key for a in request.resource_logs[0].resource.attributes]
    assert keys.count("service.name") == 1


def test_log_group_regex_none_when_unset(monkeypatch):
    """When LOG_GROUP_REGEX is not set, no extraction happens."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import _extract_log_group_attributes

    monkeypatch.setattr(function, "LOG_GROUP_REGEX", None)

    assert _extract_log_group_attributes("/aws/lambda/anything") == {}


# ---------------------------------------------------------------------------
# LOG_LINE_REGEX tests
# ---------------------------------------------------------------------------


def _log_record_attrs(
    request: logs_service_pb2.ExportLogsServiceRequest,
    index: int = 0,
) -> dict[str, str]:
    """Return the attributes of the *index*-th log record as a dict."""
    rec = request.resource_logs[0].scope_logs[0].log_records[index]
    return {a.key: a.value.string_value for a in rec.attributes}


def test_log_line_regex_extracts_attributes(monkeypatch):
    """LOG_LINE_REGEX named groups become log record attributes."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import build_export_request, decode_cw_logs_event

    monkeypatch.setattr(
        function,
        "LOG_LINE_REGEX_MAPPINGS",
        [
            function.RegexMapping(
                re.compile(r"\[(?P<severity__text>[A-Z]+)\] (?P<trace__id>[a-f0-9]+)")
            )
        ],
    )
    monkeypatch.setattr(function, "LOG_LINE_JSON_PATHS", [])

    event = make_cw_logs_event(messages=["[ERROR] deadbeef something broke"])
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    attrs = _log_record_attrs(request)
    assert attrs["severity.text"] == "ERROR"
    assert attrs["trace.id"] == "deadbeef"
    # standard attributes are still present
    assert "aws.cloudwatch.log_group" in attrs


def test_log_line_regex_no_match_adds_nothing(monkeypatch):
    """When LOG_LINE_REGEX doesn't match, no extra attributes are added."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import build_export_request, decode_cw_logs_event

    monkeypatch.setattr(
        function,
        "LOG_LINE_REGEX_MAPPINGS",
        [function.RegexMapping(re.compile(r"^WILL_NEVER_MATCH$"))],
    )
    monkeypatch.setattr(function, "LOG_LINE_JSON_PATHS", [])

    event = make_cw_logs_event(messages=["normal log line"])
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    attrs = _log_record_attrs(request)
    assert set(attrs.keys()) == {
        "aws.cloudwatch.log_group",
        "aws.cloudwatch.log_stream",
    }


def test_log_line_regex_none_when_unset(monkeypatch):
    """When LOG_LINE_REGEX is None, no extraction happens."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import _extract_log_line_regex_attributes

    monkeypatch.setattr(function, "LOG_LINE_REGEX_MAPPINGS", [])

    assert _extract_log_line_regex_attributes("anything") == {}


def test_log_line_regex_per_line_independence(monkeypatch):
    """Each log line is matched independently — one match doesn't affect another."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import build_export_request, decode_cw_logs_event

    monkeypatch.setattr(
        function,
        "LOG_LINE_REGEX_MAPPINGS",
        [function.RegexMapping(re.compile(r"\[(?P<severity__text>[A-Z]+)\]"))],
    )
    monkeypatch.setattr(function, "LOG_LINE_JSON_PATHS", [])

    event = make_cw_logs_event(
        messages=["[WARN] first", "no level here", "[DEBUG] third"]
    )
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    assert _log_record_attrs(request, 0)["severity.text"] == "WARN"
    assert "severity.text" not in _log_record_attrs(request, 1)
    assert _log_record_attrs(request, 2)["severity.text"] == "DEBUG"


def test_log_line_regex_json_format(monkeypatch):
    """LOG_LINE_REGEX accepts a JSON array with per-entry log_group filters."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import _extract_log_line_regex_attributes

    monkeypatch.setattr(
        function,
        "LOG_LINE_REGEX_MAPPINGS",
        [
            function.RegexMapping(
                re.compile(r"\[(?P<severity__text>[A-Z]+)\]"),
                log_group_regex=re.compile(r"^/aws/lambda/"),
            ),
            function.RegexMapping(
                re.compile(r"requestId=(?P<request__id>\S+)"),
            ),
        ],
    )

    # severity only extracted for matching log group
    attrs = _extract_log_line_regex_attributes(
        "[ERROR] requestId=abc123", log_group="/aws/lambda/my-fn"
    )
    assert attrs["severity.text"] == "ERROR"
    assert attrs["request.id"] == "abc123"

    # severity NOT extracted for non-matching log group, but requestId still is
    attrs = _extract_log_line_regex_attributes(
        "[ERROR] requestId=abc123", log_group="/aws/ecs/my-svc"
    )
    assert "severity.text" not in attrs
    assert attrs["request.id"] == "abc123"


def test_parse_regex_mappings_simple():
    """A plain string is parsed as a single regex applied to all log groups."""
    from otel_cw_logs_python.function import _parse_regex_mappings

    mappings = _parse_regex_mappings(r"\[(?P<severity__text>[A-Z]+)\]")
    assert len(mappings) == 1
    assert mappings[0].log_group_regex is None
    assert mappings[0].pattern.search("[WARN] hello") is not None


def test_parse_regex_mappings_json():
    """A JSON array is parsed into RegexMappings with optional log_group filters."""
    from otel_cw_logs_python.function import _parse_regex_mappings

    raw = json.dumps(
        [
            {"regex": r"\[(?P<severity__text>[A-Z]+)\]"},
            {"regex": r"rid=(?P<request__id>\S+)", "log_group": "^/aws/lambda/"},
        ]
    )
    mappings = _parse_regex_mappings(raw)
    assert len(mappings) == 2
    assert mappings[0].log_group_regex is None
    assert mappings[1].log_group_regex is not None
    assert mappings[1].matches_log_group("/aws/lambda/fn")
    assert not mappings[1].matches_log_group("/aws/ecs/svc")


def test_parse_regex_mappings_empty():
    """An empty string produces no mappings."""
    from otel_cw_logs_python.function import _parse_regex_mappings

    assert _parse_regex_mappings("") == []
    assert _parse_regex_mappings("   ") == []


def test_log_line_regex_squid_access_log(monkeypatch):
    """Squid access log regex extracts client, method, destination, and status."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import _extract_log_line_regex_attributes

    # The regex as it appears after JSON decoding of the LOG_LINE_REGEX env var.
    # In the env var, quotes are JSON-escaped (\"); after decoding they are plain ".
    squid_regex = re.compile(
        r'^(?P<client__address>[^ ]+)[^"]*'
        r' "(?P<http__request__method>[A-Z]+)'
        r" (?P<destination__address>[^ ]+)"
        r'[^"]*"'
        r" (?P<http__response__status_code>[0-9]+) .*"
    )
    monkeypatch.setattr(
        function,
        "LOG_LINE_REGEX_MAPPINGS",
        [
            function.RegexMapping(
                squid_regex, log_group_regex=re.compile(r"^/aws/ecs/squid")
            )
        ],
    )

    line = (
        "172.31.204.170 - - [05/Jul/2026:19:39:07 +0000] "
        '"CONNECT autoscaling.eu-west-2.amazonaws.com:443 HTTP/1.1" '
        "500 6392 TCP_TUNNEL:HIER_DIRECT"
    )

    # matching log group — all attributes extracted
    attrs = _extract_log_line_regex_attributes(line, log_group="/aws/ecs/squid/app")
    assert attrs == {
        "client.address": "172.31.204.170",
        "http.request.method": "CONNECT",
        "destination.address": "autoscaling.eu-west-2.amazonaws.com:443",
        "http.response.status_code": "500",
    }

    # non-matching log group — nothing extracted
    attrs = _extract_log_line_regex_attributes(line, log_group="/aws/lambda/my-fn")
    assert attrs == {}


# ---------------------------------------------------------------------------
# LOG_LINE_JSON_PATHS tests
# ---------------------------------------------------------------------------


def _jp(*args: str, log_group: str = "") -> list:
    """Shorthand to build a list of JsonPathMapping from (attr, path) pairs."""
    from otel_cw_logs_python.function import JsonPathMapping

    # args come in pairs: attr_key, dot_path[, attr_key, dot_path, ...]
    it = iter(args)
    lg = re.compile(log_group) if log_group else None
    return [
        JsonPathMapping(attr, path.split("."), lg)
        for attr, path in zip(it, it, strict=True)
    ]


def test_json_paths_extracts_top_level_keys(monkeypatch):
    """Simple top-level JSON keys are extracted as log attributes."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import build_export_request, decode_cw_logs_event

    monkeypatch.setattr(function, "LOG_LINE_REGEX_MAPPINGS", [])
    monkeypatch.setattr(
        function,
        "LOG_LINE_JSON_PATHS",
        _jp("severity.text", "level", "request.id", "requestId"),
    )

    msg = json.dumps({"level": "ERROR", "requestId": "abc-123", "message": "boom"})
    event = make_cw_logs_event(messages=[msg])
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    attrs = _log_record_attrs(request)
    assert attrs["severity.text"] == "ERROR"
    assert attrs["request.id"] == "abc-123"


def test_json_paths_extracts_nested_keys(monkeypatch):
    """Dot-separated JSON paths resolve nested objects."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import build_export_request, decode_cw_logs_event

    monkeypatch.setattr(function, "LOG_LINE_REGEX_MAPPINGS", [])
    monkeypatch.setattr(
        function,
        "LOG_LINE_JSON_PATHS",
        _jp("http.status_code", "response.statusCode"),
    )

    msg = json.dumps({"response": {"statusCode": 404, "body": "not found"}})
    event = make_cw_logs_event(messages=[msg])
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    attrs = _log_record_attrs(request)
    assert attrs["http.status_code"] == "404"


def test_json_paths_missing_key_skipped(monkeypatch):
    """Missing JSON paths are silently skipped."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import build_export_request, decode_cw_logs_event

    monkeypatch.setattr(function, "LOG_LINE_REGEX_MAPPINGS", [])
    monkeypatch.setattr(
        function,
        "LOG_LINE_JSON_PATHS",
        _jp("severity.text", "level", "trace.id", "traceId"),
    )

    msg = json.dumps({"level": "INFO"})  # no traceId
    event = make_cw_logs_event(messages=[msg])
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    attrs = _log_record_attrs(request)
    assert attrs["severity.text"] == "INFO"
    assert "trace.id" not in attrs


def test_json_paths_non_json_line_skipped(monkeypatch):
    """Non-JSON log lines are silently skipped — no error."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import build_export_request, decode_cw_logs_event

    monkeypatch.setattr(function, "LOG_LINE_REGEX_MAPPINGS", [])
    monkeypatch.setattr(function, "LOG_LINE_JSON_PATHS", _jp("severity.text", "level"))

    event = make_cw_logs_event(messages=["just a plain text log line"])
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    attrs = _log_record_attrs(request)
    assert "severity.text" not in attrs


def test_json_paths_invalid_json_skipped(monkeypatch):
    """Malformed JSON is silently skipped."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import build_export_request, decode_cw_logs_event

    monkeypatch.setattr(function, "LOG_LINE_REGEX_MAPPINGS", [])
    monkeypatch.setattr(function, "LOG_LINE_JSON_PATHS", _jp("severity.text", "level"))

    event = make_cw_logs_event(messages=["{this is not valid json}"])
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    attrs = _log_record_attrs(request)
    assert "severity.text" not in attrs


def test_json_paths_empty_config_no_extraction(monkeypatch):
    """With no JSON path mappings configured, nothing is extracted."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import _extract_log_line_json_attributes

    monkeypatch.setattr(function, "LOG_LINE_JSON_PATHS", [])

    assert _extract_log_line_json_attributes('{"level": "INFO"}') == {}


def test_json_paths_non_string_values_converted(monkeypatch):
    """Non-string values (int, bool, float) are converted to strings."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import build_export_request, decode_cw_logs_event

    monkeypatch.setattr(function, "LOG_LINE_REGEX_MAPPINGS", [])
    monkeypatch.setattr(
        function,
        "LOG_LINE_JSON_PATHS",
        _jp("http.status_code", "status", "success", "ok", "duration", "elapsed"),
    )

    msg = json.dumps({"status": 200, "ok": True, "elapsed": 1.23})
    event = make_cw_logs_event(messages=[msg])
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    attrs = _log_record_attrs(request)
    assert attrs["http.status_code"] == "200"
    assert attrs["success"] == "True"
    assert attrs["duration"] == "1.23"


def test_json_paths_mixed_json_and_text_lines(monkeypatch):
    """JSON extraction works per line — text lines are simply skipped."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import build_export_request, decode_cw_logs_event

    monkeypatch.setattr(function, "LOG_LINE_REGEX_MAPPINGS", [])
    monkeypatch.setattr(function, "LOG_LINE_JSON_PATHS", _jp("severity.text", "level"))

    event = make_cw_logs_event(
        messages=[
            json.dumps({"level": "ERROR", "msg": "bad"}),
            "plain text line",
            json.dumps({"level": "INFO", "msg": "ok"}),
        ]
    )
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    assert _log_record_attrs(request, 0)["severity.text"] == "ERROR"
    assert "severity.text" not in _log_record_attrs(request, 1)
    assert _log_record_attrs(request, 2)["severity.text"] == "INFO"


# ---------------------------------------------------------------------------
# LOG_LINE_REGEX + LOG_LINE_JSON_PATHS combined
# ---------------------------------------------------------------------------


def test_json_paths_override_regex_on_conflict(monkeypatch):
    """When both extractors produce the same key, JSON path wins."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import build_export_request, decode_cw_logs_event

    monkeypatch.setattr(
        function,
        "LOG_LINE_REGEX_MAPPINGS",
        [function.RegexMapping(re.compile(r"\[(?P<severity__text>[A-Z]+)\]"))],
    )
    monkeypatch.setattr(function, "LOG_LINE_JSON_PATHS", _jp("severity.text", "level"))

    msg = "[WARN] " + json.dumps({"level": "ERROR"})
    event = make_cw_logs_event(messages=[msg])
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    attrs = _log_record_attrs(request)
    assert attrs["severity.text"] == "ERROR"


def test_both_extractors_merge(monkeypatch):
    """Regex and JSON extractors produce different keys that all appear."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import build_export_request, decode_cw_logs_event

    monkeypatch.setattr(
        function,
        "LOG_LINE_REGEX_MAPPINGS",
        [function.RegexMapping(re.compile(r"(?P<trace__id>[a-f0-9]{8})"))],
    )
    monkeypatch.setattr(function, "LOG_LINE_JSON_PATHS", _jp("severity.text", "level"))

    msg = "abcdef01 " + json.dumps({"level": "DEBUG"})
    event = make_cw_logs_event(messages=[msg])
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    attrs = _log_record_attrs(request)
    assert attrs["trace.id"] == "abcdef01"
    assert attrs["severity.text"] == "DEBUG"


# ---------------------------------------------------------------------------
# _parse_json_path_mappings tests
# ---------------------------------------------------------------------------


def test_parse_json_path_mappings_simple():
    """The simple comma-separated format is parsed correctly."""
    from otel_cw_logs_python.function import _parse_json_path_mappings

    mappings = _parse_json_path_mappings("severity.text=level,trace.id=ctx.traceId")
    assert len(mappings) == 2
    assert mappings[0].attr_key == "severity.text"
    assert mappings[0].path == ["level"]
    assert mappings[0].log_group_regex is None
    assert mappings[1].attr_key == "trace.id"
    assert mappings[1].path == ["ctx", "traceId"]


def test_parse_json_path_mappings_simple_empty():
    """Empty and whitespace-only strings produce no mappings."""
    from otel_cw_logs_python.function import _parse_json_path_mappings

    assert _parse_json_path_mappings("") == []
    assert _parse_json_path_mappings("  ") == []


def test_parse_json_path_mappings_simple_bad_entries():
    """Entries without = or with empty key/value are skipped."""
    from otel_cw_logs_python.function import _parse_json_path_mappings

    assert _parse_json_path_mappings("bad_entry_without_equals") == []
    assert _parse_json_path_mappings("=nokey") == []
    assert _parse_json_path_mappings("novalue=") == []


def test_parse_json_path_mappings_json_format():
    """The JSON array format is parsed with optional log_group filters."""
    from otel_cw_logs_python.function import _parse_json_path_mappings

    env = json.dumps(
        [
            {"attr": "severity.text", "path": "level"},
            {
                "attr": "request.id",
                "path": "ctx.requestId",
                "log_group": "^/aws/lambda/",
            },
        ]
    )
    mappings = _parse_json_path_mappings(env)

    assert len(mappings) == 2
    assert mappings[0].attr_key == "severity.text"
    assert mappings[0].path == ["level"]
    assert mappings[0].log_group_regex is None
    assert mappings[1].attr_key == "request.id"
    assert mappings[1].path == ["ctx", "requestId"]
    assert mappings[1].log_group_regex is not None
    assert mappings[1].matches_log_group("/aws/lambda/my-fn")
    assert not mappings[1].matches_log_group("/aws/ecs/task")


def test_parse_json_path_mappings_json_empty_array():
    """An empty JSON array produces no mappings."""
    from otel_cw_logs_python.function import _parse_json_path_mappings

    assert _parse_json_path_mappings("[]") == []


def test_parse_json_path_mappings_json_skips_invalid_entries():
    """JSON entries missing attr or path are skipped."""
    from otel_cw_logs_python.function import _parse_json_path_mappings

    env = json.dumps([{"attr": "", "path": "level"}, {"attr": "x", "path": ""}])
    assert _parse_json_path_mappings(env) == []


# ---------------------------------------------------------------------------
# Per-mapping log_group filter tests
# ---------------------------------------------------------------------------


def test_json_path_log_group_filter_match(monkeypatch):
    """A mapping with a log_group filter extracts when the log group matches."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import (
        JsonPathMapping,
        build_export_request,
        decode_cw_logs_event,
    )

    monkeypatch.setattr(function, "LOG_LINE_REGEX_MAPPINGS", [])
    monkeypatch.setattr(
        function,
        "LOG_LINE_JSON_PATHS",
        [JsonPathMapping("severity.text", ["level"], re.compile(r"^/aws/lambda/"))],
    )

    msg = json.dumps({"level": "ERROR"})
    event = make_cw_logs_event(log_group="/aws/lambda/my-fn", messages=[msg])
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    assert _log_record_attrs(request)["severity.text"] == "ERROR"


def test_json_path_log_group_filter_no_match(monkeypatch):
    """A mapping with a log_group filter is skipped when the log group doesn't match."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import (
        JsonPathMapping,
        build_export_request,
        decode_cw_logs_event,
    )

    monkeypatch.setattr(function, "LOG_LINE_REGEX_MAPPINGS", [])
    monkeypatch.setattr(
        function,
        "LOG_LINE_JSON_PATHS",
        [JsonPathMapping("severity.text", ["level"], re.compile(r"^/aws/lambda/"))],
    )

    msg = json.dumps({"level": "ERROR"})
    event = make_cw_logs_event(log_group="/aws/ecs/some-task", messages=[msg])
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")

    assert "severity.text" not in _log_record_attrs(request)


def test_json_path_mixed_filtered_and_unfiltered(monkeypatch):
    """Mappings with and without log_group filters coexist correctly."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import (
        JsonPathMapping,
        build_export_request,
        decode_cw_logs_event,
    )

    monkeypatch.setattr(function, "LOG_LINE_REGEX_MAPPINGS", [])
    monkeypatch.setattr(
        function,
        "LOG_LINE_JSON_PATHS",
        [
            # always extract level
            JsonPathMapping("severity.text", ["level"]),
            # only extract requestId for lambda log groups
            JsonPathMapping("request.id", ["requestId"], re.compile(r"^/aws/lambda/")),
        ],
    )

    msg = json.dumps({"level": "INFO", "requestId": "abc-123"})

    # lambda log group — both extracted
    event = make_cw_logs_event(log_group="/aws/lambda/fn", messages=[msg])
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")
    attrs = _log_record_attrs(request)
    assert attrs["severity.text"] == "INFO"
    assert attrs["request.id"] == "abc-123"

    # ecs log group — only level extracted
    event = make_cw_logs_event(log_group="/aws/ecs/task", messages=[msg])
    payload = decode_cw_logs_event(event)
    request = build_export_request(payload, "eu-west-2")
    attrs = _log_record_attrs(request)
    assert attrs["severity.text"] == "INFO"
    assert "request.id" not in attrs


# ---------------------------------------------------------------------------
# Firehose transform handler tests
# ---------------------------------------------------------------------------


def make_firehose_record(
    log_group: str = "/aws/lambda/my-function",
    log_stream: str = "2024/01/01/[$LATEST]abc123",
    owner: str = "123456789012",
    messages: list[str] | None = None,
    message_type: str = "DATA_MESSAGE",
    record_id: str = "record-1",
) -> dict[str, str]:
    """Build a single Firehose record containing a CW Logs payload."""
    if messages is None:
        messages = ["hello world"]

    payload = {
        "messageType": message_type,
        "owner": owner,
        "logGroup": log_group,
        "logStream": log_stream,
        "subscriptionFilters": ["test-filter"],
        "logEvents": [
            {
                "id": f"event-{i}",
                "timestamp": int(time.time() * 1000) - (i * 1000),
                "message": msg,
            }
            for i, msg in enumerate(messages)
        ],
    }

    compressed = gzip.compress(json.dumps(payload).encode())
    encoded = base64.b64encode(compressed).decode()
    return {"recordId": record_id, "data": encoded}


def test_handler_routes_firehose_event():
    """An event with 'records' is handled as a Firehose transform event."""
    from otel_cw_logs_python.function import handler

    event = {"records": [make_firehose_record(messages=["line1"])]}

    with patch("otel_cw_logs_python.function.send_to_otlp") as mock_send:
        mock_send.return_value = True
        result = handler(event, None)

    assert "records" in result
    assert len(result["records"]) == 1
    assert result["records"][0]["result"] == "Dropped"
    assert result["records"][0]["recordId"] == "record-1"


def test_handler_routes_cw_logs_event():
    """An event with 'awslogs' is handled as a direct CW Logs event."""
    from otel_cw_logs_python.function import handler

    event = make_cw_logs_event(messages=["line1"])

    with patch("otel_cw_logs_python.function.send_to_otlp") as mock_send:
        mock_send.return_value = True
        result = handler(event, None)

    assert result["status"] == "ok"
    assert result["logCount"] == 1


def test_firehose_handler_send_failure():
    """A failed OTLP export marks the Firehose record as ProcessingFailed."""
    from otel_cw_logs_python.function import handler

    event = {"records": [make_firehose_record(record_id="fail-1")]}

    with patch("otel_cw_logs_python.function.send_to_otlp") as mock_send:
        mock_send.return_value = False
        result = handler(event, None)

    assert result["records"][0]["result"] == "ProcessingFailed"
    assert result["records"][0]["recordId"] == "fail-1"


def test_firehose_handler_multiple_records():
    """Multiple Firehose records are processed independently."""
    from otel_cw_logs_python.function import handler

    event = {
        "records": [
            make_firehose_record(record_id="r1", messages=["msg1"]),
            make_firehose_record(record_id="r2", messages=["msg2"]),
            make_firehose_record(record_id="r3", messages=["msg3"]),
        ]
    }

    with patch("otel_cw_logs_python.function.send_to_otlp") as mock_send:
        mock_send.side_effect = [True, False, True]
        result = handler(event, None)

    assert len(result["records"]) == 3
    assert result["records"][0]["result"] == "Dropped"
    assert result["records"][1]["result"] == "ProcessingFailed"
    assert result["records"][2]["result"] == "Dropped"


def test_firehose_handler_control_message():
    """Control messages in Firehose records are dropped (success) without sending."""
    from otel_cw_logs_python.function import handler

    event = {
        "records": [
            make_firehose_record(record_id="ctrl-1", message_type="CONTROL_MESSAGE"),
        ]
    }

    with patch("otel_cw_logs_python.function.send_to_otlp") as mock_send:
        result = handler(event, None)

    assert result["records"][0]["result"] == "Dropped"
    mock_send.assert_not_called()


def test_firehose_handler_deadline_close(caplog):
    """Firehose records fail without sending when deadline is close."""
    from otel_cw_logs_python.function import handler

    context = SimpleNamespace(get_remaining_time_in_millis=lambda: 1000)
    record_id = "deadline-1\r\nforged log entry"
    event = {"records": [make_firehose_record(record_id=record_id)]}

    with patch("otel_cw_logs_python.function.send_to_otlp") as mock_send:
        result = handler(event, context)

    assert result["records"][0]["result"] == "ProcessingFailed"
    assert result["records"][0]["recordId"] == record_id
    assert "deadline-1forgedlogentry" in caplog.text
    assert "forged log entry" not in caplog.text
    mock_send.assert_not_called()


def test_firehose_handler_exception(caplog):
    """An exception processing a Firehose record marks it as ProcessingFailed."""
    from otel_cw_logs_python.function import handler

    # Invalid base64 data will cause an exception
    record_id = "bad-1\r\nforged log entry"
    event = {"records": [{"recordId": record_id, "data": "not-valid-base64!!!"}]}

    result = handler(event, None)

    assert result["records"][0]["result"] == "ProcessingFailed"
    assert result["records"][0]["recordId"] == record_id
    assert "Error processing record bad-1forgedlogentry" in caplog.text
    assert "forged log entry" not in caplog.text


# ---------------------------------------------------------------------------
# Instrumentation tests
# ---------------------------------------------------------------------------


def test_build_forwarder_metrics_request():
    """Operational metrics request has the expected structure."""
    from otel_cw_logs_python.function import _build_forwarder_metrics_request

    request = _build_forwarder_metrics_request(
        records_processed=5, records_failed=1, export_duration_ms=123.45
    )

    assert len(request.resource_metrics) == 1
    rm = request.resource_metrics[0]
    res_attrs = {a.key: a.value.string_value for a in rm.resource.attributes}
    assert res_attrs["cloud.provider"] == "aws"
    assert "service.name" in res_attrs

    sm = rm.scope_metrics[0]
    assert sm.scope.name == "otel_cw_logs_python"
    assert len(sm.metrics) == 3

    by_name = {m.name: m for m in sm.metrics}
    assert by_name["forwarder.records.processed"].gauge.data_points[0].as_int == 5
    assert by_name["forwarder.records.failed"].gauge.data_points[0].as_int == 1
    assert by_name["forwarder.export.duration"].gauge.data_points[
        0
    ].as_double == pytest.approx(123.45)


def test_build_forwarder_metrics_includes_resource_attrs(monkeypatch):
    """OTEL_RESOURCE_ATTRIBUTES are merged into instrumentation metrics."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import (
        _build_forwarder_metrics_request,
        _parse_resource_attributes,
    )

    monkeypatch.setattr(
        function,
        "OTEL_RESOURCE_ATTRIBUTES",
        _parse_resource_attributes("deployment.environment.name=production"),
    )

    request = _build_forwarder_metrics_request(1, 0, 10.0)
    res_attrs = {
        a.key: a.value.string_value
        for a in request.resource_metrics[0].resource.attributes
    }
    assert res_attrs["deployment.environment.name"] == "production"


@pytest.mark.parametrize(
    ("endpoint", "expected_url"),
    [
        (
            "https://collector.example.com:4318",
            "https://collector.example.com:4318/v1/metrics",
        ),
        (
            "http://collector.example.com:4318",
            "http://collector.example.com:4318/v1/metrics",
        ),
        (
            "https://collector.example.com/v1/metrics",
            "https://collector.example.com/v1/metrics",
        ),
    ],
)
def test_http_metrics_url(monkeypatch, endpoint, expected_url):
    """The http/protobuf metrics URL gets /v1/metrics appended unless already present."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import http_metrics_url

    monkeypatch.setattr(function, "OTLP_ENDPOINT", endpoint)
    assert http_metrics_url() == expected_url


def test_emit_forwarder_metrics_no_endpoint(monkeypatch):
    """emit_forwarder_metrics is a no-op when endpoint is empty."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import emit_forwarder_metrics

    monkeypatch.setattr(function, "OTLP_ENDPOINT", "")
    # Should not raise
    emit_forwarder_metrics(1, 0, 10.0)


def test_handler_emits_forwarder_metrics():
    """The handler calls emit_forwarder_metrics after processing."""
    from otel_cw_logs_python.function import handler

    event = make_cw_logs_event(messages=["line1", "line2"])

    with (
        patch("otel_cw_logs_python.function.send_to_otlp") as mock_send,
        patch("otel_cw_logs_python.function.emit_forwarder_metrics") as mock_emit,
    ):
        mock_send.return_value = True
        handler(event, None)

        mock_emit.assert_called_once()
        args = mock_emit.call_args
        assert args[0][0] == 1  # records_processed
        assert args[0][1] == 0  # records_failed


def test_firehose_handler_emits_forwarder_metrics():
    """The Firehose handler calls emit_forwarder_metrics with correct stats."""
    from otel_cw_logs_python.function import handler

    event = {
        "records": [
            make_firehose_record(record_id="r1", messages=["msg1"]),
            make_firehose_record(record_id="r2", messages=["msg2"]),
        ]
    }

    with (
        patch("otel_cw_logs_python.function.send_to_otlp") as mock_send,
        patch("otel_cw_logs_python.function.emit_forwarder_metrics") as mock_emit,
    ):
        mock_send.side_effect = [True, False]
        handler(event, None)

        mock_emit.assert_called_once()
        args = mock_emit.call_args
        assert args[0][0] == 2  # records_processed
        assert args[0][1] == 1  # records_failed


# ---------------------------------------------------------------------------
# Rate limiting tests
# ---------------------------------------------------------------------------


def test_parse_rate_limit_valid():
    """Valid numeric strings are parsed correctly."""
    from otel_cw_logs_python.function import _parse_rate_limit

    assert _parse_rate_limit("10") == 10.0
    assert _parse_rate_limit("0.5") == 0.5
    assert _parse_rate_limit(" 5 ") == 5.0


def test_parse_rate_limit_zero_and_empty():
    """Zero and empty values mean unlimited."""
    from otel_cw_logs_python.function import _parse_rate_limit

    assert _parse_rate_limit("") == 0.0
    assert _parse_rate_limit("0") == 0.0
    assert _parse_rate_limit("  ") == 0.0


def test_parse_rate_limit_negative():
    """Negative values are clamped to zero (unlimited)."""
    from otel_cw_logs_python.function import _parse_rate_limit

    assert _parse_rate_limit("-5") == 0.0


def test_parse_rate_limit_invalid():
    """Non-numeric strings default to unlimited."""
    from otel_cw_logs_python.function import _parse_rate_limit

    assert _parse_rate_limit("abc") == 0.0


def test_rate_limiter_unlimited():
    """A RateLimiter with rate 0 never sleeps."""
    from otel_cw_logs_python.function import RateLimiter

    limiter = RateLimiter(0.0)
    with patch("otel_cw_logs_python.function.time") as mock_time:
        mock_time.monotonic.return_value = 1.0
        limiter.wait()
        mock_time.sleep.assert_not_called()


def test_rate_limiter_paces_calls():
    """A RateLimiter with rate 2/s enforces a 0.5s interval."""
    from otel_cw_logs_python.function import RateLimiter

    limiter = RateLimiter(2.0)
    # first call — no previous send, should set _last_send but no sleep needed
    # (because _last_send starts at 0.0 and monotonic() will be much larger)
    limiter.wait()
    # second call immediately — should sleep ~0.5s
    # Instead of actually sleeping, test the logic via the internal state
    assert limiter._min_interval == pytest.approx(0.5)


def test_rate_limiter_no_sleep_when_interval_elapsed():
    """No sleep when enough time has passed since the last send."""
    from otel_cw_logs_python.function import RateLimiter

    limiter = RateLimiter(10.0)  # 0.1s interval
    limiter._last_send = time.monotonic() - 1.0  # 1s ago, well past the interval
    with patch("otel_cw_logs_python.function.time") as mock_time:
        mock_time.monotonic.return_value = time.monotonic()
        limiter.wait()
        mock_time.sleep.assert_not_called()


def test_rate_limiter_sleeps_when_called_too_soon():
    """RateLimiter sleeps for the remaining interval when called before min_interval."""
    from otel_cw_logs_python.function import RateLimiter

    limiter = RateLimiter(10.0)  # 0.1s interval
    now = 1000.0
    limiter._last_send = now - 0.03  # only 30ms ago, need to sleep 70ms more

    with patch("otel_cw_logs_python.function.time") as mock_time:
        mock_time.monotonic.return_value = now
        limiter.wait()
        mock_time.sleep.assert_called_once_with(pytest.approx(0.07, abs=1e-6))


def test_rate_limiter_first_call_no_sleep():
    """The very first call to wait() never sleeps (_last_send starts at 0)."""
    from otel_cw_logs_python.function import RateLimiter

    limiter = RateLimiter(5.0)  # 0.2s interval
    assert limiter._last_send == 0.0

    with patch("otel_cw_logs_python.function.time") as mock_time:
        mock_time.monotonic.return_value = 100.0
        limiter.wait()
        mock_time.sleep.assert_not_called()


def test_rate_limiter_updates_last_send():
    """wait() updates _last_send to the current monotonic time after sleeping."""
    from otel_cw_logs_python.function import RateLimiter

    limiter = RateLimiter(4.0)  # 0.25s interval
    now = 500.0
    after_sleep = 500.1

    with patch("otel_cw_logs_python.function.time") as mock_time:
        mock_time.monotonic.side_effect = [now, after_sleep]
        limiter.wait()

    assert limiter._last_send == after_sleep


def test_rate_limiter_successive_waits_enforce_interval():
    """Multiple rapid wait() calls each enforce the min interval."""
    from otel_cw_logs_python.function import RateLimiter

    limiter = RateLimiter(10.0)  # 0.1s interval

    # Simulate three rapid calls at t=100, then immediately after each
    with patch("otel_cw_logs_python.function.time") as mock_time:
        # First call: monotonic returns 100 (well past _last_send=0), no sleep
        mock_time.monotonic.side_effect = [100.0, 100.0]
        limiter.wait()
        mock_time.sleep.assert_not_called()

    with patch("otel_cw_logs_python.function.time") as mock_time:
        # Second call: only 0.02s later, should sleep 0.08s
        mock_time.monotonic.side_effect = [100.02, 100.1]
        limiter.wait()
        mock_time.sleep.assert_called_once_with(pytest.approx(0.08, abs=1e-6))

    with patch("otel_cw_logs_python.function.time") as mock_time:
        # Third call: 0.05s after last send (100.1), should sleep 0.05s
        mock_time.monotonic.side_effect = [100.15, 100.2]
        limiter.wait()
        mock_time.sleep.assert_called_once_with(pytest.approx(0.05, abs=1e-6))


def test_rate_limiter_high_rate():
    """A very high rate (1000/s) results in a tiny min_interval."""
    from otel_cw_logs_python.function import RateLimiter

    limiter = RateLimiter(1000.0)
    assert limiter._min_interval == pytest.approx(0.001)


def test_rate_limiter_fractional_rate():
    """A fractional rate (0.5/s) results in a 2s interval."""
    from otel_cw_logs_python.function import RateLimiter

    limiter = RateLimiter(0.5)
    assert limiter._min_interval == pytest.approx(2.0)


def test_rate_limiter_negative_rate_treated_as_unlimited():
    """A negative rate is treated the same as 0 (unlimited)."""
    from otel_cw_logs_python.function import RateLimiter

    limiter = RateLimiter(-1.0)
    assert limiter._min_interval == 0.0
    with patch("otel_cw_logs_python.function.time") as mock_time:
        mock_time.monotonic.return_value = 1.0
        limiter.wait()
        mock_time.sleep.assert_not_called()


def test_parse_rate_limit_float_variants():
    """Various float format strings are parsed correctly."""
    from otel_cw_logs_python.function import _parse_rate_limit

    assert _parse_rate_limit("1e2") == 100.0
    assert _parse_rate_limit(".5") == 0.5
    assert _parse_rate_limit("1000") == 1000.0


def test_handler_calls_rate_limiter(monkeypatch):
    """The handler calls the rate limiter before sending."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import RateLimiter, handler

    mock_limiter = RateLimiter(0.0)
    mock_limiter.wait = MagicMock()  # type: ignore[method-assign]
    monkeypatch.setattr(function, "_rate_limiter", mock_limiter)

    event = make_cw_logs_event(messages=["line1"])

    with patch("otel_cw_logs_python.function.send_to_otlp") as mock_send:
        mock_send.return_value = True
        handler(event, None)

    mock_limiter.wait.assert_called_once()


def test_handler_rate_limiter_not_called_for_control_message(monkeypatch):
    """Control messages skip the rate limiter."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import RateLimiter, handler

    mock_limiter = RateLimiter(0.0)
    mock_limiter.wait = MagicMock()  # type: ignore[method-assign]
    monkeypatch.setattr(function, "_rate_limiter", mock_limiter)

    event = make_cw_logs_event(message_type="CONTROL_MESSAGE")

    with patch("otel_cw_logs_python.function.send_to_otlp") as mock_send:
        handler(event, None)

    mock_limiter.wait.assert_not_called()
    mock_send.assert_not_called()


def test_firehose_handler_rate_limiter_called_per_record(monkeypatch):
    """The Firehose handler calls the rate limiter once per data record."""
    import otel_cw_logs_python.function as function
    from otel_cw_logs_python.function import RateLimiter, handler

    mock_limiter = RateLimiter(0.0)
    mock_limiter.wait = MagicMock()  # type: ignore[method-assign]
    monkeypatch.setattr(function, "_rate_limiter", mock_limiter)

    event = {
        "records": [
            make_firehose_record(record_id="r1", messages=["msg1"]),
            make_firehose_record(record_id="r2", messages=["msg2"]),
            make_firehose_record(record_id="r3", messages=["msg3"]),
        ]
    }

    with patch("otel_cw_logs_python.function.send_to_otlp") as mock_send:
        mock_send.return_value = True
        handler(event, None)

    assert mock_limiter.wait.call_count == 3
