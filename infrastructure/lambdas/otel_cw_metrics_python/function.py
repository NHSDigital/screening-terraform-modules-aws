import base64
import dataclasses
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
from opentelemetry.proto.collector.metrics.v1 import (
    metrics_service_pb2,
    metrics_service_pb2_grpc,
)
from opentelemetry.proto.common.v1 import common_pb2
from opentelemetry.proto.metrics.v1 import metrics_pb2
from opentelemetry.proto.resource.v1 import resource_pb2


@dataclasses.dataclass(frozen=True)
class AttributeAuthTokenMapping:
    attr_key: str
    value_pattern: re.Pattern[str]
    token_name: str

    def matches_attributes(self, attrs: dict[str, str]) -> bool:
        value = attrs.get(self.attr_key, "")
        return bool(self.value_pattern.search(value))


logger = logging.getLogger()
logger.setLevel(logging.INFO)

OTLP_ENDPOINT = os.environ.get("OTLP_ENDPOINT", "")
OTLP_AUTH_TOKEN = os.environ.get("OTLP_AUTH_TOKEN", "")
OTLP_AUTH_TOKEN_MAP_ENV = os.environ.get("OTLP_AUTH_TOKEN_MAP", "")
OTLP_AUTH_TOKEN_SECRET_ARN_MAP_ENV = os.environ.get(
    "OTLP_AUTH_TOKEN_SECRET_ARN_MAP", ""
)
OTEL_ATTRIBUTE_AUTH_TOKEN_MAP_ENV = os.environ.get("OTEL_ATTRIBUTE_AUTH_TOKEN_MAP", "")
OTLP_PROTOCOL = os.environ.get("OTLP_PROTOCOL", "grpc")

# "aws" passes metrics through (with Dimensions expanded); "prom" rewrites them
# into prometheus-style series named like yet-another-cloudwatch-exporter's
METRIC_FORMAT = os.environ.get("METRIC_FORMAT", "prom")
# regexes applied to the final (formatted) metric names: metrics must match
# KEEP_METRICS_REGEX (when set) and must not match EXCLUDE_METRICS_REGEX (when set)
KEEP_METRICS_ENV = os.environ.get("KEEP_METRICS_REGEX", "")
EXCLUDE_METRICS_ENV = os.environ.get("EXCLUDE_METRICS_REGEX", "")
KEEP_METRICS_REGEX = re.compile(KEEP_METRICS_ENV) if KEEP_METRICS_ENV else None
EXCLUDE_METRICS_REGEX = re.compile(EXCLUDE_METRICS_ENV) if EXCLUDE_METRICS_ENV else None
SANITIZE_FOR_LOG_REGEX = re.compile(r"[A-Za-z0-9._:/+=-]", re.ASCII)


OTEL_RESOURCE_ATTRIBUTES_ENV = os.environ.get("OTEL_RESOURCE_ATTRIBUTES", "")


def _parse_resource_attributes(env: str) -> dict[str, str]:
    if not env.strip():
        return {}
    return {
        k: v
        for k, v in (pair.strip().split("=") for pair in env.strip().split(","))
        if v
    }


def _parse_auth_token_map(
    otlp_auth_token: str, otlp_auth_token_map_env: str
) -> dict[str, str]:
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


def _parse_attribute_auth_token_mappings(env: str) -> list[AttributeAuthTokenMapping]:
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


def _validate_attribute_auth_token_mappings(
    mappings: list[AttributeAuthTokenMapping], auth_token_map: dict[str, str]
) -> None:
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
ATTRIBUTE_AUTH_TOKEN_MAPPINGS = _parse_attribute_auth_token_mappings(
    OTEL_ATTRIBUTE_AUTH_TOKEN_MAP_ENV
)
_validate_attribute_auth_token_mappings(ATTRIBUTE_AUTH_TOKEN_MAPPINGS, TOKEN_NAME_MAP)

if not OTLP_ENDPOINT:
    logger.error("OTLP_ENDPOINT not configured")

DEFAULT_EXPORT_TIMEOUT_SECONDS = 60.0

DEADLINE_SAFETY_MARGIN_SECONDS = 10.0

# retry policy for the http/protobuf transport, mirroring the gRPC service config
HTTP_RETRY_ATTEMPTS = 5
HTTP_RETRY_BACKOFF_SECONDS = 1.0
HTTP_RETRYABLE_STATUSES = {429, 500, 502, 503, 504}

# retry transient failures inside gRPC rather than failing the whole record
GRPC_SERVICE_CONFIG = json.dumps(
    {
        "methodConfig": [
            {
                "name": [
                    {
                        "service": "opentelemetry.proto.collector.metrics.v1.MetricsService"
                    }
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

_stub = None


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


def get_stub() -> metrics_service_pb2_grpc.MetricsServiceStub:
    """Create the gRPC channel/stub once and reuse it across records and warm invocations."""
    global _stub
    if _stub is None:
        options = [
            ("grpc.service_config", GRPC_SERVICE_CONFIG),
            ("grpc.enable_retries", 1),
        ]
        target, use_tls = parse_endpoint(OTLP_ENDPOINT)
        if use_tls:
            channel = grpc.secure_channel(
                target, grpc.ssl_channel_credentials(), options=options
            )
        else:
            channel = grpc.insecure_channel(target, options=options)
        _stub = metrics_service_pb2_grpc.MetricsServiceStub(channel)
    return _stub


def decode_varint(data: bytes, pos: int = 0) -> tuple[int, int]:
    """Decode a varint at pos and return (value, new_pos)."""
    result = 0
    shift = 0
    while pos < len(data):
        byte = data[pos]
        result |= (byte & 0x7F) << shift
        pos += 1
        if not (byte & 0x80):
            return result, pos
        shift += 7
    raise ValueError("Invalid varint")


def parse_metrics_requests(
    data: bytes,
) -> list[metrics_service_pb2.ExportMetricsServiceRequest]:
    """Parse CloudWatch Metric Stream format: one or more length-prefixed
    ExportMetricsServiceRequest messages concatenated in a single record."""
    requests = []
    pos = 0
    while pos < len(data):
        length, pos = decode_varint(data, pos)
        end = pos + length
        if end > len(data):
            raise ValueError(
                f"Message length {length} at pos {pos} exceeds record size {len(data)}"
            )
        request = metrics_service_pb2.ExportMetricsServiceRequest()
        request.ParseFromString(data[pos:end])
        requests.append(request)
        pos = end
    return requests


def _set_resource_attributes(resource: Any) -> None:
    """Set the resource attributes on a Resource."""
    if not OTEL_RESOURCE_ATTRIBUTES:
        return
    remaining = OTEL_RESOURCE_ATTRIBUTES.copy()
    for attr in resource.attributes:
        value = remaining.get(attr.key)
        if value is None:
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


def _expand_dimensions(dp: Any) -> None:
    """Promote the entries of a data point's 'Dimensions' kvlist attribute
    (e.g. ClusterName, ServiceName) to top-level data point attributes, and drop
    the redundant MetricName attribute (the metric name already carries it)."""
    dimensions = []
    kept = []
    changed = False
    for attr in dp.attributes:
        if (
            attr.key == "Dimensions"
            and attr.value.WhichOneof("value") == "kvlist_value"
        ):
            dimensions.extend(attr.value.kvlist_value.values)
            changed = True
        elif attr.key == "MetricName":
            changed = True
        else:
            kept.append(attr)
    if changed:
        del dp.attributes[:]
        dp.attributes.extend(kept)
        dp.attributes.extend(dimensions)


_RE_LEADING_JUNK = re.compile(r"^[^a-zA-Z0-9]+")
# a word is either an acronym run before the next word (CPU in CPUUtilization,
# 5XX in 5XXError) or an uppercase/digit/lowercase-led run with its
# lowercase/digit tail (Volume, EC2, Utilization, 4XX, used)
_RE_WORDS = re.compile(
    r"\d*[A-Z]+(?=[A-Z][a-z])|(?:\d+[A-Z]*|[A-Z]+|[a-z])[a-z\d]*", re.ASCII
)


def prom_name(name: str) -> str:
    """Convert to a prometheus-style snake_case name, e.g.
    VolumeBytes -> volume_bytes, CPUUtilization -> cpu_utilization, AWS/EC2 -> aws_ec2.
    """
    name = _RE_LEADING_JUNK.sub("", name)
    if not name:
        return name
    name = name[0].upper() + name[1:]
    return "_".join(_RE_WORDS.findall(name)).lower()


def percentile_suffix(quantile: float) -> str:
    """Name a percentile quantile as a prom series suffix, e.g. 0.95 -> p95
    and 0.999 -> p99_9."""
    percentile = f"{quantile * 100:.6f}".rstrip("0").rstrip(".")
    return "p" + percentile.replace(".", "_")


def summary_statistics(dp: metrics_pb2.SummaryDataPoint) -> dict[str, float]:
    """Extract the CloudWatch statistics from a metric stream summary data point,
    keyed by the prom series suffix.

    CloudWatch encodes SampleCount as count, Sum as sum, Minimum as the q0
    quantile and Maximum as the q1 quantile. Additional percentile statistics
    configured on the stream arrive as further quantiles (e.g. p95 as q0.95)."""
    stats = {
        "sum": dp.sum,
        "sample_count": float(dp.count),
    }
    for quantile in dp.quantile_values:
        if quantile.quantile == 0.0:
            stats["min"] = quantile.value
        elif quantile.quantile == 1.0:
            stats["max"] = quantile.value
        elif 0.0 < quantile.quantile < 1.0:
            stats[percentile_suffix(quantile.quantile)] = quantile.value
    if dp.count:
        stats["avg"] = dp.sum / dp.count
    return stats


# short service aliases matching NHSDigital/terraform-aws-metrics-lambda services.py,
# pre-normalised to snake_case; namespaces not listed fall back to prom_name(namespace)
SERVICE_ALIASES = {
    "CWAgent": "cwagent",
    "AWS/Usage": "usage",
    "AWS/CertificateManager": "acm",
    "AWS/ACMPrivateCA": "acm_pca",
    "AmazonMWAA": "airflow",
    "AWS/MWAA": "mwaa",
    "AWS/ApplicationELB": "alb",
    "AWS/AppStream": "appstream",
    "AWS/Backup": "backup",
    "AWS/ApiGateway": "apigateway",
    "AWS/AmazonMQ": "mq",
    "AWS/AppRunner": "apprunner",
    "AWS/AppSync": "appsync",
    "AWS/Athena": "athena",
    "AWS/AutoScaling": "asg",
    "AWS/ElasticBeanstalk": "beanstalk",
    "AWS/Billing": "billing",
    "AWS/Cassandra": "cassandra",
    "AWS/CloudFront": "cloudfront",
    "AWS/Cognito": "cognito_idp",
    "AWS/DataSync": "datasync",
    "AWS/DirectoryService": "ds",
    "AWS/DMS": "dms",
    "AWS/DDoSProtection": "shield",
    "AWS/DocDB": "docdb",
    "AWS/DX": "dx",
    "AWS/DynamoDB": "dynamodb",
    "AWS/EBS": "ebs",
    "AWS/ElastiCache": "ec",
    "AWS/MemoryDB": "memorydb",
    "AWS/EC2": "ec2",
    "AWS/EC2Spot": "ec2_spot",
    "AWS/EC2CapacityReservations": "ec2_capacity_reservations",
    "AWS/ECS": "ecs_svc",
    "ECS/ContainerInsights": "ecs_containerinsights",
    "ContainerInsights": "containerinsights",
    "AWS/EFS": "efs",
    "AWS/ELB": "elb",
    "AWS/ElasticMapReduce": "emr",
    "AWS/EMRServerless": "emr_serverless",
    "AWS/ES": "es",
    "AWS/Firehose": "firehose",
    "AWS/FSx": "fsx",
    "AWS/GameLift": "gamelift",
    "AWS/GatewayELB": "gwlb",
    "AWS/GlobalAccelerator": "ga",
    "Glue": "glue",
    "AWS/IoT": "iot",
    "AWS/Kafka": "kafka",
    "AWS/KafkaConnect": "kafkaconnect",
    "AWS/Kinesis": "kinesis",
    "AWS/KinesisAnalytics": "kinesis_analytics",
    "AWS/KMS": "kms",
    "AWS/Lambda": "lambda",
    "LambdaInsights": "lambdainsights",
    "AWS/Logs": "logs",
    "AWS/MediaConnect": "mediaconnect",
    "AWS/MediaConvert": "mediaconvert",
    "AWS/MediaPackage": "mediapackage",
    "AWS/MediaLive": "medialive",
    "AWS/MediaTailor": "mediatailor",
    "AWS/Neptune": "neptune",
    "AWS/NetworkFirewall": "nfw",
    "AWS/NATGateway": "ngw",
    "AWS/NetworkELB": "nlb",
    "AWS/PrivateLinkEndpoints": "vpc_endpoint",
    "AWS/PrivateLinkServices": "vpc_endpoint_service",
    "AWS/Prometheus": "amp",
    "AWS/QLDB": "qldb",
    "AWS/QuickSight": "quicksight",
    "AWS/RDS": "rds",
    "AWS/Redshift-Serverless": "redshift",
    "AWS/Route53Resolver": "route53_resolver",
    "AWS/Route53": "route53",
    "AWS/RUM": "rum",
    "AWS/S3": "s3",
    "AWS/Scheduler": "scheduler",
    "AWS/ECR": "ecr",
    "AWS/Timestream": "timestream",
    "AWS/SecretsManager": "secretsmanager",
    "AWS/SES": "ses",
    "AWS/States": "sfn",
    "AWS/SNS": "sns",
    "AWS/SQS": "sqs",
    "AWS/StorageGateway": "storagegateway",
    "AWS/Transfer": "transfer",
    "AWS/TransitGateway": "tgw",
    "AWS/TrustedAdvisor": "trustedadvisor",
    "AWS/VPN": "vpn",
    "AWS/ClientVPN": "clientvpn",
    "AWS/WAFV2": "wafv2",
    "AWS/WorkSpaces": "workspaces",
    "AWS/AOSS": "aoss",
    "AWS/SageMaker": "sagemaker",
    "/aws/sagemaker/Endpoints": "sagemaker_endpoints",
    "/aws/sagemaker/InferenceComponents": "sagemaker_inference_components",
    "/aws/sagemaker/TrainingJobs": "sagemaker_training",
    "/aws/sagemaker/ProcessingJobs": "sagemaker_processing",
    "/aws/sagemaker/TransformJobs": "sagemaker_transform",
    "/aws/sagemaker/InferenceRecommendationsJobs": "sagemaker_inf_rec",
    "AWS/Sagemaker/ModelBuildingPipeline": "sagemaker_model_building_pipeline",
    "AWS/IPAM": "ipam",
    "AWS/Bedrock": "bedrock",
    "AWS/Events": "event_rule",
    "AWS/VpcLattice": "vpc_lattice",
    "AWS/Network Manager": "networkmanager",
}


def _prom_base_name(namespace: str, otlp_name: str) -> str:
    """Build the prom series base name aws_<service>_<metricname>, using the short
    service alias for the namespace when one is known (AWS/ApplicationELB -> alb).

    The metric name comes from the OTLP metric name, e.g. AWS/ECS/LiveTaskCount."""
    parts = otlp_name.removeprefix("amazonaws.com/").rsplit("/", 1)
    if len(parts) == 2:
        namespace = namespace or parts[0]
        metric_name = parts[1]
    else:
        metric_name = otlp_name
    service = SERVICE_ALIASES.get(namespace) or prom_name(namespace)
    base = f"{service}_{prom_name(metric_name)}"
    return base if base.startswith("aws_") else f"aws_{base}"


def _prom_labels(
    dp: metrics_pb2.SummaryDataPoint, common_labels: dict[str, str]
) -> tuple[str, list[common_pb2.KeyValue]]:
    """Split a data point's attributes into (namespace, labels).

    Expects _expand_dimensions to have run first: any attribute other than
    Namespace is treated as a dimension and prefixed dimension_."""
    namespace = ""
    labels = [
        common_pb2.KeyValue(key=key, value=common_pb2.AnyValue(string_value=value))
        for key, value in common_labels.items()
        if value
    ]
    for attr in dp.attributes:
        if attr.key == "Namespace":
            namespace = attr.value.string_value
        else:
            labels.append(
                common_pb2.KeyValue(key=prom_name(attr.key), value=attr.value)
            )
    return namespace, labels


def _convert_summary_metric(
    metric: metrics_pb2.Metric,
    common_labels: dict[str, str],
    series_by_name: dict[str, metrics_pb2.Metric],
    new_metrics: list[metrics_pb2.Metric],
) -> None:
    """Convert one summary metric into per-statistic gauge series."""
    for dp in metric.summary.data_points:
        namespace, labels = _prom_labels(dp, common_labels)
        base = _prom_base_name(namespace, metric.name)
        for stat, value in summary_statistics(dp).items():
            series_name = f"{base}_{stat}"
            series = series_by_name.get(series_name)
            if series is None:
                series = metrics_pb2.Metric(name=series_name, unit=metric.unit)
                series_by_name[series_name] = series
                new_metrics.append(series)
            new_dp = series.gauge.data_points.add()
            new_dp.start_time_unix_nano = dp.start_time_unix_nano
            new_dp.time_unix_nano = dp.time_unix_nano
            new_dp.as_double = value
            new_dp.attributes.extend(labels)


def _prom_common_labels(resource: Any) -> dict[str, str]:
    """Extract the labels shared by all prom series from the resource attributes."""
    resource_attrs = {a.key: a.value.string_value for a in resource.attributes}
    return {
        "account_id": resource_attrs.get("cloud.account.id", ""),
        "region": resource_attrs.get("cloud.region", ""),
    }


def _metric_name_allowed(name: str) -> bool:
    """Apply the keep/remove regex filters to a final (formatted) metric name."""
    if KEEP_METRICS_REGEX and not KEEP_METRICS_REGEX.search(name):
        return False
    return not (EXCLUDE_METRICS_REGEX and EXCLUDE_METRICS_REGEX.search(name))


def transform_request(request: metrics_service_pb2.ExportMetricsServiceRequest) -> None:
    """Apply all transformations in a single walk of the request:

    - set the resource attributes
    - expand each data point's Dimensions kvlist into top-level attributes
    - strip the amazonaws.com/ metric name prefix
    - in prom format, rewrite summary metrics into prometheus-style gauge series
      (aws_<namespace>_<metricname>_<statistic>) with dimension_<Name>, account_id
      and region labels
    - drop metrics whose final name fails the KEEP_METRICS/REMOVE_METRICS filters"""
    prom = METRIC_FORMAT == "prom"
    for rm in request.resource_metrics:
        _set_resource_attributes(rm.resource)
        common_labels = _prom_common_labels(rm.resource) if prom else {}
        for sm in rm.scope_metrics:
            new_metrics: list[metrics_pb2.Metric] = []
            series_by_name: dict[str, metrics_pb2.Metric] = {}
            for metric in sm.metrics:
                metric.name = metric.name.removeprefix("amazonaws.com/")
                data_type = metric.WhichOneof("data")
                if data_type:
                    for dp in getattr(metric, data_type).data_points:
                        _expand_dimensions(dp)
                if prom and data_type == "summary":
                    _convert_summary_metric(
                        metric, common_labels, series_by_name, new_metrics
                    )
                else:
                    new_metrics.append(metric)
            filtering = KEEP_METRICS_REGEX or EXCLUDE_METRICS_REGEX
            if filtering:
                new_metrics = [m for m in new_metrics if _metric_name_allowed(m.name)]
            if prom or filtering:
                del sm.metrics[:]
                sm.metrics.extend(new_metrics)


def _log_partial_success(
    response: metrics_service_pb2.ExportMetricsServiceResponse,
) -> None:
    partial = response.partial_success
    if partial.rejected_data_points:
        logger.warning(
            f"OTLP endpoint rejected {partial.rejected_data_points} data points: {partial.error_message}"
        )


def _default_auth_token() -> str:
    return _get_auth_token("default")


def _resolve_auth_token_for_resource_metrics(
    rm: metrics_pb2.ResourceMetrics,
) -> str:
    """Resolve auth token based on resource attributes of a single ResourceMetrics."""
    attrs: dict[str, str] = {}
    if rm.HasField("resource"):
        for attr in rm.resource.attributes:
            attrs[attr.key] = attr.value.string_value
    selected_name = "default"
    for mapping in ATTRIBUTE_AUTH_TOKEN_MAPPINGS:
        if mapping.matches_attributes(attrs):
            selected_name = mapping.token_name
    return _get_auth_token(selected_name)


def _split_request_by_auth_token(
    request: metrics_service_pb2.ExportMetricsServiceRequest,
) -> dict[str, metrics_service_pb2.ExportMetricsServiceRequest]:
    """Group ResourceMetrics by resolved auth token into separate requests."""
    batches: dict[str, list[metrics_pb2.ResourceMetrics]] = {}
    for rm in request.resource_metrics:
        token = _resolve_auth_token_for_resource_metrics(rm)
        batches.setdefault(token, []).append(rm)
    return {
        token: metrics_service_pb2.ExportMetricsServiceRequest(resource_metrics=rms)
        for token, rms in batches.items()
    }


def _export_grpc(
    request: metrics_service_pb2.ExportMetricsServiceRequest,
    timeout: float,
    auth_token: str,
) -> None:
    metadata = []
    if auth_token:
        metadata.append(("authorization", f"Bearer {auth_token}"))
    response = get_stub().Export(
        request,
        timeout=timeout,
        metadata=metadata,
        compression=grpc.Compression.Gzip,
    )
    _log_partial_success(response)


def http_metrics_url() -> str:
    """Build the http/protobuf metrics URL from OTLP_ENDPOINT, appending the
    standard /v1/metrics path unless the endpoint already includes it."""
    target, use_tls = parse_endpoint(OTLP_ENDPOINT)
    scheme = "https" if use_tls else "http"
    url = f"{scheme}://{target.rstrip('/')}"
    if not url.endswith("/v1/metrics"):
        url = f"{url}/v1/metrics"
    return url


def _export_http(
    request: metrics_service_pb2.ExportMetricsServiceRequest,
    timeout: float,
    auth_token: str,
) -> None:
    body = gzip.compress(request.SerializeToString())
    headers = {
        "Content-Type": "application/x-protobuf",
        "Content-Encoding": "gzip",
    }
    if auth_token:
        headers["Authorization"] = f"Bearer {auth_token}"
    http_request = urllib.request.Request(
        http_metrics_url(), data=body, headers=headers, method="POST"
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
            response = metrics_service_pb2.ExportMetricsServiceResponse()
            response.ParseFromString(payload)
            _log_partial_success(response)
        except Exception:
            logger.warning("Could not parse OTLP http export response")


def send_to_otlp(
    metrics_data: bytes, timeout: float = DEFAULT_EXPORT_TIMEOUT_SECONDS
) -> bool:
    if not OTLP_ENDPOINT:
        logger.error("OTLP_ENDPOINT not configured")
        return False

    export = _export_http if OTLP_PROTOCOL == "http/protobuf" else _export_grpc

    try:
        requests = parse_metrics_requests(metrics_data)

        for request in requests:
            transform_request(request)
            if not any(
                sm.metrics for rm in request.resource_metrics for sm in rm.scope_metrics
            ):
                # every metric was filtered out; nothing to send for this message
                continue
            for auth_token, batch_request in _split_request_by_auth_token(
                request
            ).items():
                export(batch_request, timeout, auth_token)
        return True
    except grpc.RpcError as e:
        logger.error(f"gRPC error sending metrics: {e.code()} - {e.details()}")
        return False
    except urllib.error.URLError as e:
        logger.error(f"HTTP error sending metrics: {e}")
        return False
    except Exception:
        logger.exception("Error sending metrics to OTLP endpoint")
        return False


# ---------------------------------------------------------------------------
# Forwarder instrumentation — best-effort operational metrics
# ---------------------------------------------------------------------------

LAMBDA_FUNCTION_NAME = os.environ.get(
    "AWS_LAMBDA_FUNCTION_NAME", "otel-cw-metrics-forwarder"
)

AWS_REGION = os.environ.get(
    "AWS_REGION", os.environ.get("AWS_DEFAULT_REGION", "eu-west-2")
)


def _build_forwarder_metrics_request(
    records_processed: int,
    records_failed: int,
    export_duration_ms: float,
) -> metrics_service_pb2.ExportMetricsServiceRequest:
    """Build an OTLP metrics request with operational gauges."""
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
                            name="otel_cw_metrics_python",
                        ),
                        metrics=metrics,
                    )
                ],
            )
        ]
    )


def emit_forwarder_metrics(
    records_processed: int,
    records_failed: int,
    export_duration_ms: float,
    timeout: float = 5.0,
) -> None:
    """Send operational metrics best-effort."""
    if not OTLP_ENDPOINT:
        return
    timeout = min(timeout, 5.0)
    if timeout <= 0:
        return
    try:
        request = _build_forwarder_metrics_request(
            records_processed, records_failed, export_duration_ms
        )
        export = _export_http if OTLP_PROTOCOL == "http/protobuf" else _export_grpc
        export(request, timeout, _default_auth_token())
    except Exception:
        logger.warning("Failed to send forwarder metrics", exc_info=True)


def remaining_timeout(context: Any) -> float:
    """Cap the per-call timeout so we fail fast instead of dying at the Lambda deadline."""
    if context is not None and hasattr(context, "get_remaining_time_in_millis"):
        remaining_millis = float(context.get_remaining_time_in_millis())
        remaining = remaining_millis / 1000.0 - DEADLINE_SAFETY_MARGIN_SECONDS
        return min(DEFAULT_EXPORT_TIMEOUT_SECONDS, remaining)
    return DEFAULT_EXPORT_TIMEOUT_SECONDS


def sanitize_for_log(value: Any) -> str:
    """Keep bounded allowlisted characters for logging, or mark empty results invalid."""
    if not isinstance(value, str):
        return "<invalid>"
    sanitized = "".join(SANITIZE_FOR_LOG_REGEX.findall(value))[:128]
    return sanitized or "<invalid>"


def handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    output_records = []
    records_processed = 0
    records_failed = 0
    export_duration_ms = 0.0

    for record in event.get("records", []):
        record_id = record["recordId"]
        log_record_id = sanitize_for_log(record_id)
        try:
            timeout = remaining_timeout(context)
            if timeout <= 0:
                logger.error(
                    f"Lambda deadline too close, failing record {log_record_id} without sending"
                )
                success = False
            else:
                payload = base64.b64decode(record["data"])
                start = time.monotonic()
                success = send_to_otlp(payload, timeout)
                export_duration_ms += (time.monotonic() - start) * 1000

            records_processed += 1
            if success:
                output_records.append(
                    {"recordId": record_id, "result": "Dropped", "data": record["data"]}
                )
            else:
                records_failed += 1
                output_records.append(
                    {
                        "recordId": record_id,
                        "result": "ProcessingFailed",
                        "data": record["data"],
                    }
                )

        except Exception:
            logger.exception(f"Error processing record {log_record_id}")
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
