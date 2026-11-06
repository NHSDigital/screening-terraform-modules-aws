import base64
import json
import os
import re
import time
from types import SimpleNamespace
from typing import cast
from unittest.mock import patch

import pytest
from opentelemetry.proto.collector.metrics.v1 import metrics_service_pb2
from opentelemetry.proto.common.v1 import common_pb2
from opentelemetry.proto.metrics.v1 import metrics_pb2
from opentelemetry.proto.resource.v1 import resource_pb2

os.environ.setdefault("OTLP_AUTH_TOKEN", "test-default-token")


def encode_varint(value: int) -> bytes:
    """Encode an integer as a varint."""
    result = []
    while value > 0x7F:
        result.append((value & 0x7F) | 0x80)
        value >>= 7
    result.append(value)
    return bytes(result)


def create_synthetic_metrics(
    namespace: str = "AWS/EC2",
    metric_names: list[str] | None = None,
    num_datapoints: int = 1,
    dimensions: dict[str, str] | None = None,
    as_summary: bool = False,
) -> bytes:
    """Create synthetic metrics in CloudWatch Metric Stream format (length-prefixed protobuf).

    as_summary=True mirrors what CloudWatch actually streams: summary data points with
    count=SampleCount, sum=Sum, quantile 0=Minimum and quantile 1=Maximum."""
    if metric_names is None:
        metric_names = ["CPUUtilization", "NetworkIn", "NetworkOut"]

    request = metrics_service_pb2.ExportMetricsServiceRequest()

    rm = request.resource_metrics.add()
    rm.resource.CopyFrom(resource_pb2.Resource())

    rm.resource.attributes.append(
        common_pb2.KeyValue(
            key="cloud.provider",
            value=common_pb2.AnyValue(string_value="aws"),
        )
    )
    rm.resource.attributes.append(
        common_pb2.KeyValue(
            key="cloud.account.id",
            value=common_pb2.AnyValue(string_value="123"),
        )
    )
    rm.resource.attributes.append(
        common_pb2.KeyValue(
            key="cloud.region",
            value=common_pb2.AnyValue(string_value="eu-west-2"),
        )
    )

    sm = rm.scope_metrics.add()

    for metric_name in metric_names:
        metric = sm.metrics.add()
        metric.name = f"amazonaws.com/{namespace}/{metric_name}"
        metric.unit = "Count"

        for i in range(num_datapoints):
            if as_summary:
                dp = metric.summary.data_points.add()
                dp.count = 4
                dp.sum = 100.0
                q_min = dp.quantile_values.add()
                q_min.quantile = 0.0
                q_min.value = 10.0
                q_max = dp.quantile_values.add()
                q_max.quantile = 1.0
                q_max.value = 40.0
            else:
                dp = metric.gauge.data_points.add()
                dp.as_double = 42.0 + i
            dp.time_unix_nano = int(time.time() * 1e9) - (i * 60_000_000_000)

            dp.attributes.append(
                common_pb2.KeyValue(
                    key="Namespace",
                    value=common_pb2.AnyValue(string_value=namespace),
                )
            )
            dp.attributes.append(
                common_pb2.KeyValue(
                    key="MetricName",
                    value=common_pb2.AnyValue(string_value=metric_name),
                )
            )
            if dimensions:
                dp.attributes.append(
                    common_pb2.KeyValue(
                        key="Dimensions",
                        value=common_pb2.AnyValue(
                            kvlist_value=common_pb2.KeyValueList(
                                values=[
                                    common_pb2.KeyValue(
                                        key=k,
                                        value=common_pb2.AnyValue(string_value=v),
                                    )
                                    for k, v in dimensions.items()
                                ]
                            )
                        ),
                    )
                )

    serialized = cast(bytes, request.SerializeToString())
    length_prefix = encode_varint(len(serialized))
    return length_prefix + serialized


@pytest.fixture
def synthetic_record():
    """Generate a single synthetic metrics record."""
    data = create_synthetic_metrics()
    return base64.b64encode(data).decode("utf-8")


def test_synthetic_metrics_roundtrip():
    """Test that synthetic metrics can be created and parsed."""
    from otel_cw_metrics_python.function import parse_metrics_requests

    data = create_synthetic_metrics(
        namespace="AWS/Lambda",
        metric_names=["Invocations", "Duration", "Errors"],
        num_datapoints=5,
    )

    requests = parse_metrics_requests(data)

    assert len(requests) == 1
    request = requests[0]

    assert len(request.resource_metrics) == 1
    rm = request.resource_metrics[0]

    assert len(rm.resource.attributes) == 3
    attr_dict = {attr.key: attr.value.string_value for attr in rm.resource.attributes}
    assert attr_dict["cloud.provider"] == "aws"
    assert attr_dict["cloud.account.id"] == "123"
    assert attr_dict["cloud.region"] == "eu-west-2"

    assert len(rm.scope_metrics) == 1
    sm = rm.scope_metrics[0]

    assert len(sm.metrics) == 3
    for metric in sm.metrics:
        assert metric.name.startswith("amazonaws.com/AWS/Lambda/")
        assert len(metric.gauge.data_points) == 5


def test_handler_with_synthetic_metrics(synthetic_record):
    """Test the handler with synthetic metrics."""
    from otel_cw_metrics_python.function import handler

    event = {
        "records": [
            {"recordId": "synthetic-1", "data": synthetic_record},
        ]
    }

    with patch("otel_cw_metrics_python.function.send_to_otlp") as mock_send:
        mock_send.return_value = True

        result = handler(event, None)

        assert len(result["records"]) == 1
        assert result["records"][0]["result"] == "Dropped"
        mock_send.assert_called_once()

        call_args = mock_send.call_args[0][0]
        assert isinstance(call_args, bytes)


def test_handler_send_failure(synthetic_record):
    """Test the handler handles send failures correctly."""
    from otel_cw_metrics_python.function import handler

    event = {
        "records": [
            {"recordId": "synthetic-1", "data": synthetic_record},
        ]
    }

    with patch("otel_cw_metrics_python.function.send_to_otlp") as mock_send:
        mock_send.return_value = False

        result = handler(event, None)

        assert len(result["records"]) == 1
        assert result["records"][0]["result"] == "ProcessingFailed"


@pytest.mark.parametrize(
    ("endpoint", "expected_target", "expected_tls"),
    [
        (
            "https://otel-collector.example.com:4317",
            "otel-collector.example.com:4317",
            True,
        ),
        (
            "grpcs://otel-collector.example.com:4317",
            "otel-collector.example.com:4317",
            True,
        ),
        (
            "http://otel-collector.example.com:4317",
            "otel-collector.example.com:4317",
            False,
        ),
        (
            "grpc://otel-collector.example.com:4317",
            "otel-collector.example.com:4317",
            False,
        ),
        ("otel-collector.example.com:4317", "otel-collector.example.com:4317", True),
    ],
)
def test_parse_endpoint(endpoint, expected_target, expected_tls):
    """Endpoint schemes map to the right gRPC target and TLS setting."""
    from otel_cw_metrics_python.function import parse_endpoint

    target, use_tls = parse_endpoint(endpoint)

    assert target == expected_target
    assert use_tls is expected_tls


@pytest.fixture(params=["aws", "prom"])
def metric_format(request, monkeypatch):
    """Run a test in both metric formats."""
    import otel_cw_metrics_python.function as function

    monkeypatch.setattr(function, "METRIC_FORMAT", request.param)
    return request.param


def test_default_format_is_prom(monkeypatch):
    """Without the METRIC_FORMAT env var the lambda defaults to prom, matching terraform."""
    import importlib

    import otel_cw_metrics_python.function as function

    monkeypatch.delenv("METRIC_FORMAT", raising=False)
    reloaded = importlib.reload(function)

    assert reloaded.METRIC_FORMAT == "prom"


def test_add_deployment_environment_name(monkeypatch, metric_format):
    """The deployment.environment.name resource attribute is added when set."""
    import otel_cw_metrics_python.function as function
    from otel_cw_metrics_python.function import (
        _parse_resource_attributes,
        parse_metrics_requests,
        transform_request,
    )

    monkeypatch.setattr(
        function,
        "OTEL_RESOURCE_ATTRIBUTES",
        _parse_resource_attributes(
            "deployment.environment.name=production,another=something"
        ),
    )

    request = parse_metrics_requests(create_synthetic_metrics())[0]
    transform_request(request)

    for rm in request.resource_metrics:
        attrs = {attr.key: attr.value.string_value for attr in rm.resource.attributes}
        assert attrs["deployment.environment.name"] == "production"
        assert attrs["another"] == "something"
        # existing attributes are untouched
        assert attrs["cloud.provider"] == "aws"


def test_add_deployment_environment_name_overwrites_existing(
    monkeypatch, metric_format
):
    """An existing environment name is overwritten, not duplicated."""
    import otel_cw_metrics_python.function as function
    from otel_cw_metrics_python.function import (
        _parse_resource_attributes,
        parse_metrics_requests,
        transform_request,
    )

    monkeypatch.setattr(
        function,
        "OTEL_RESOURCE_ATTRIBUTES",
        _parse_resource_attributes(
            "deployment.environment.name=staging,another=something"
        ),
    )

    request = parse_metrics_requests(create_synthetic_metrics())[0]
    request.resource_metrics[0].resource.attributes.append(
        common_pb2.KeyValue(
            key="deployment.environment.name",
            value=common_pb2.AnyValue(string_value="stale-value"),
        )
    )

    transform_request(request)

    keys = [attr.key for attr in request.resource_metrics[0].resource.attributes]
    assert keys.count("deployment.environment.name") == 1
    attrs = {
        attr.key: attr.value.string_value
        for attr in request.resource_metrics[0].resource.attributes
    }
    assert attrs["deployment.environment.name"] == "staging"


def test_add_deployment_environment_name_disabled_when_unset(
    monkeypatch, metric_format
):
    """No environment name is added when its value is empty."""
    import otel_cw_metrics_python.function as function
    from otel_cw_metrics_python.function import (
        _parse_resource_attributes,
        parse_metrics_requests,
        transform_request,
    )

    monkeypatch.setattr(
        function,
        "OTEL_RESOURCE_ATTRIBUTES",
        _parse_resource_attributes("deployment.environment.name=,another=something"),
    )

    request = parse_metrics_requests(create_synthetic_metrics())[0]
    transform_request(request)

    for rm in request.resource_metrics:
        keys = [attr.key for attr in rm.resource.attributes]
        assert "deployment.environment.name" not in keys


def test_parse_auth_token_map_from_single_token():
    """OTLP_AUTH_TOKEN is mapped to the default named token."""
    from otel_cw_metrics_python.function import _parse_auth_token_map

    assert _parse_auth_token_map("sekret", "") == {"default": "sekret"}


def test_parse_auth_token_map_from_map():
    """OTLP_AUTH_TOKEN_MAP supports named tokens when a default exists."""
    from otel_cw_metrics_python.function import _parse_auth_token_map

    assert _parse_auth_token_map(
        "", '{"default":"default-token","prod":"prod-token"}'
    ) == {
        "default": "default-token",
        "prod": "prod-token",
    }


def test_parse_auth_token_map_mutually_exclusive_raises():
    """OTLP_AUTH_TOKEN and OTLP_AUTH_TOKEN_MAP cannot be set together."""
    from otel_cw_metrics_python.function import _parse_auth_token_map

    with pytest.raises(
        ValueError, match="Set either OTLP_AUTH_TOKEN or OTLP_AUTH_TOKEN_MAP, not both"
    ):
        _parse_auth_token_map("sekret", '{"default":"another"}')


def test_parse_auth_token_map_requires_configuration():
    """A default auth token config is required at startup."""
    from otel_cw_metrics_python.function import _parse_auth_token_map

    with pytest.raises(ValueError, match="Set OTLP_AUTH_TOKEN or OTLP_AUTH_TOKEN_MAP"):
        _parse_auth_token_map("", "")


def test_parse_auth_token_map_requires_default_when_mapped():
    """OTLP_AUTH_TOKEN_MAP must include a non-empty default token."""
    from otel_cw_metrics_python.function import _parse_auth_token_map

    with pytest.raises(
        ValueError,
        match="OTLP_AUTH_TOKEN_MAP must include a non-empty 'default' token",
    ):
        _parse_auth_token_map("", '{"prod":"prod-token"}')


def test_parse_auth_token_map_non_json_raises():
    """OTLP_AUTH_TOKEN_MAP must be valid JSON."""
    from otel_cw_metrics_python.function import _parse_auth_token_map

    with pytest.raises(json.JSONDecodeError):
        _parse_auth_token_map("", "{not-json}")


def test_secret_auth_token_is_cached(monkeypatch):
    import otel_cw_metrics_python.function as function

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
    import otel_cw_metrics_python.function as function

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
    import otel_cw_metrics_python.function as function

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


def test_parse_attribute_auth_token_mappings_empty():
    """Empty OTEL_ATTRIBUTE_AUTH_TOKEN_MAP yields no mappings."""
    from otel_cw_metrics_python.function import _parse_attribute_auth_token_mappings

    assert _parse_attribute_auth_token_mappings("") == []


def test_parse_attribute_auth_token_mappings_valid():
    """Attribute auth token mappings parse key=regex selectors."""
    from otel_cw_metrics_python.function import _parse_attribute_auth_token_mappings

    mappings = _parse_attribute_auth_token_mappings(
        '{"service.name=^platform-":"platform"}'
    )

    assert len(mappings) == 1
    assert mappings[0].matches_attributes({"service.name": "platform-api"})
    assert not mappings[0].matches_attributes({"service.name": "worker"})
    assert mappings[0].token_name == "platform"


def test_parse_attribute_auth_token_mappings_invalid_regex():
    """Invalid selector regexes are rejected."""
    from otel_cw_metrics_python.function import _parse_attribute_auth_token_mappings

    with pytest.raises(re.error):
        _parse_attribute_auth_token_mappings('{"service.name=[":"platform"}')


def test_validate_attribute_auth_token_mappings():
    """Known token names are accepted."""
    from otel_cw_metrics_python.function import (
        AttributeAuthTokenMapping,
        _validate_attribute_auth_token_mappings,
    )

    mappings = [
        AttributeAuthTokenMapping(
            attr_key="service.name",
            value_pattern=re.compile(r"^platform-"),
            token_name="platform",
        )
    ]

    _validate_attribute_auth_token_mappings(
        mappings, {"default": "default-token", "platform": "platform-token"}
    )


def test_validate_attribute_auth_token_mappings_rejects_unknown_token_names():
    """Attribute auth token mappings must reference known token names."""
    from otel_cw_metrics_python.function import (
        AttributeAuthTokenMapping,
        _validate_attribute_auth_token_mappings,
    )

    mappings = [
        AttributeAuthTokenMapping(
            attr_key="service.name",
            value_pattern=re.compile(r"^platform-"),
            token_name="missing",
        )
    ]

    with pytest.raises(
        ValueError,
        match="OTEL_ATTRIBUTE_AUTH_TOKEN_MAP references unknown auth token names",
    ):
        _validate_attribute_auth_token_mappings(mappings, {"default": "default-token"})


def test_resolve_auth_token_for_resource_metrics_defaults_without_mappings(monkeypatch):
    """Uses the default token when no attribute mappings are configured."""
    import otel_cw_metrics_python.function as function
    from otel_cw_metrics_python.function import (
        _resolve_auth_token_for_resource_metrics,
    )

    monkeypatch.setattr(function, "AUTH_TOKEN_MAP", {"default": "default-token"})
    monkeypatch.setattr(function, "ATTRIBUTE_AUTH_TOKEN_MAPPINGS", [])

    rm = metrics_pb2.ResourceMetrics()

    assert _resolve_auth_token_for_resource_metrics(rm) == "default-token"


def test_resolve_auth_token_for_resource_metrics_matching_mapping(monkeypatch):
    """Matching resource attributes choose the mapped auth token."""
    import otel_cw_metrics_python.function as function
    from otel_cw_metrics_python.function import (
        AttributeAuthTokenMapping,
        _resolve_auth_token_for_resource_metrics,
        parse_metrics_requests,
    )

    monkeypatch.setattr(
        function,
        "AUTH_TOKEN_MAP",
        {"default": "default-token", "platform": "platform-token"},
    )
    monkeypatch.setattr(
        function,
        "ATTRIBUTE_AUTH_TOKEN_MAPPINGS",
        [
            AttributeAuthTokenMapping(
                attr_key="service.name",
                value_pattern=re.compile(r"^platform-"),
                token_name="platform",
            )
        ],
    )

    request = parse_metrics_requests(create_synthetic_metrics())[0]
    request.resource_metrics[0].resource.attributes.append(
        common_pb2.KeyValue(
            key="service.name",
            value=common_pb2.AnyValue(string_value="platform-api"),
        )
    )

    assert (
        _resolve_auth_token_for_resource_metrics(request.resource_metrics[0])
        == "platform-token"
    )


def test_resolve_auth_token_for_resource_metrics_falls_back_when_no_match(monkeypatch):
    """Non-matching resource attributes fall back to the default token."""
    import otel_cw_metrics_python.function as function
    from otel_cw_metrics_python.function import (
        AttributeAuthTokenMapping,
        _resolve_auth_token_for_resource_metrics,
        parse_metrics_requests,
    )

    monkeypatch.setattr(
        function,
        "AUTH_TOKEN_MAP",
        {"default": "default-token", "platform": "platform-token"},
    )
    monkeypatch.setattr(
        function,
        "ATTRIBUTE_AUTH_TOKEN_MAPPINGS",
        [
            AttributeAuthTokenMapping(
                attr_key="service.name",
                value_pattern=re.compile(r"^platform-"),
                token_name="platform",
            )
        ],
    )

    request = parse_metrics_requests(create_synthetic_metrics())[0]
    request.resource_metrics[0].resource.attributes.append(
        common_pb2.KeyValue(
            key="service.name",
            value=common_pb2.AnyValue(string_value="worker"),
        )
    )

    assert (
        _resolve_auth_token_for_resource_metrics(request.resource_metrics[0])
        == "default-token"
    )


def test_split_request_by_auth_token(monkeypatch):
    """Requests with mixed resource attributes are split by auth token."""
    import otel_cw_metrics_python.function as function
    from otel_cw_metrics_python.function import (
        AttributeAuthTokenMapping,
        _split_request_by_auth_token,
        parse_metrics_requests,
    )

    monkeypatch.setattr(
        function,
        "AUTH_TOKEN_MAP",
        {"default": "default-token", "prod": "prod-token"},
    )
    monkeypatch.setattr(
        function,
        "ATTRIBUTE_AUTH_TOKEN_MAPPINGS",
        [
            AttributeAuthTokenMapping(
                attr_key="deployment.environment",
                value_pattern=re.compile(r"^prod$"),
                token_name="prod",
            )
        ],
    )

    request = parse_metrics_requests(create_synthetic_metrics())[0]
    # First ResourceMetrics gets "prod" attribute
    request.resource_metrics[0].resource.attributes.append(
        common_pb2.KeyValue(
            key="deployment.environment",
            value=common_pb2.AnyValue(string_value="prod"),
        )
    )
    # Add a second ResourceMetrics with "dev" attribute
    rm_dev = metrics_pb2.ResourceMetrics()
    rm_dev.resource.CopyFrom(request.resource_metrics[0].resource)
    rm_dev.resource.attributes[-1].value.string_value = "dev"
    request.resource_metrics.append(rm_dev)

    batches = _split_request_by_auth_token(request)
    assert len(batches) == 2
    assert "prod-token" in batches
    assert "default-token" in batches


def test_send_to_otlp_uses_attribute_selected_auth_token(monkeypatch, synthetic_record):
    """send_to_otlp resolves auth tokens from request resource attributes."""
    import otel_cw_metrics_python.function as function
    from otel_cw_metrics_python.function import (
        AttributeAuthTokenMapping,
        send_to_otlp,
    )

    monkeypatch.setattr(function, "OTLP_ENDPOINT", "grpcs://collector.example.com:4317")
    monkeypatch.setattr(
        function, "AUTH_TOKEN_MAP", {"default": "default", "pid": "pid"}
    )
    monkeypatch.setattr(
        function,
        "ATTRIBUTE_AUTH_TOKEN_MAPPINGS",
        [
            AttributeAuthTokenMapping(
                attr_key="cloud.account.id",
                value_pattern=re.compile(r"^123$"),
                token_name="pid",
            )
        ],
    )

    captured: list[str] = []

    def fake_export(
        request: metrics_service_pb2.ExportMetricsServiceRequest,
        timeout: float,
        auth_token: str,
    ) -> None:
        captured.append(auth_token)

    monkeypatch.setattr(function, "_export_grpc", fake_export)

    assert send_to_otlp(base64.b64decode(synthetic_record)) is True
    assert captured == ["pid"]


def test_expand_dimensions(metric_format):
    """Dimension entries are promoted to top-level data point attributes."""
    from otel_cw_metrics_python.function import (
        parse_metrics_requests,
        transform_request,
    )

    data = create_synthetic_metrics(
        namespace="AWS/ECS",
        metric_names=["LiveTaskCount"],
        dimensions={"ClusterName": "fargate", "ServiceName": "squid"},
    )
    request = parse_metrics_requests(data)[0]

    transform_request(request)

    for rm in request.resource_metrics:
        for sm in rm.scope_metrics:
            for metric in sm.metrics:
                for dp in metric.gauge.data_points:
                    attrs = {
                        attr.key: attr.value.string_value for attr in dp.attributes
                    }
                    assert attrs["ClusterName"] == "fargate"
                    assert attrs["ServiceName"] == "squid"
                    # Namespace survives; the Dimensions wrapper and the
                    # redundant MetricName attribute are removed
                    assert attrs["Namespace"] == "AWS/ECS"
                    assert "MetricName" not in attrs
                    assert "Dimensions" not in attrs


def test_expand_dimensions_no_dimensions_attribute(metric_format):
    """Data points without a Dimensions attribute only lose the MetricName attribute."""
    from otel_cw_metrics_python.function import (
        parse_metrics_requests,
        transform_request,
    )

    data = create_synthetic_metrics(metric_names=["CPUUtilization"])
    request = parse_metrics_requests(data)[0]

    transform_request(request)

    dp = request.resource_metrics[0].scope_metrics[0].metrics[0].gauge.data_points[0]
    keys = [attr.key for attr in dp.attributes]
    assert keys == ["Namespace"]


def test_to_prometheus(monkeypatch):
    """Summary metrics become one prometheus-style gauge series per statistic."""
    import otel_cw_metrics_python.function as function
    from otel_cw_metrics_python.function import (
        parse_metrics_requests,
        transform_request,
    )

    monkeypatch.setattr(function, "METRIC_FORMAT", "prom")

    data = create_synthetic_metrics(
        namespace="AWS/ECS",
        metric_names=["LiveTaskCount"],
        dimensions={"ClusterName": "fargate", "ServiceName": "squid"},
        as_summary=True,
    )
    request = parse_metrics_requests(data)[0]

    transform_request(request)

    metrics = {m.name: m for m in request.resource_metrics[0].scope_metrics[0].metrics}

    expected_values = {
        "aws_ecs_svc_live_task_count_sum": 100.0,
        "aws_ecs_svc_live_task_count_sample_count": 4.0,
        "aws_ecs_svc_live_task_count_min": 10.0,
        "aws_ecs_svc_live_task_count_max": 40.0,
        "aws_ecs_svc_live_task_count_avg": 25.0,
    }
    assert set(metrics) == set(expected_values)

    for name, expected in expected_values.items():
        dps = metrics[name].gauge.data_points
        assert len(dps) == 1
        assert dps[0].as_double == expected

        labels = {attr.key: attr.value.string_value for attr in dps[0].attributes}
        assert labels == {
            "account_id": "123",
            "region": "eu-west-2",
            "cluster_name": "fargate",
            "service_name": "squid",
        }


def test_to_prometheus_percentiles(monkeypatch):
    """Percentile quantiles become p<N> series; out-of-range quantiles are ignored."""
    import otel_cw_metrics_python.function as function
    from otel_cw_metrics_python.function import (
        parse_metrics_requests,
        transform_request,
    )

    monkeypatch.setattr(function, "METRIC_FORMAT", "prom")

    data = create_synthetic_metrics(
        namespace="AWS/ApiGateway",
        metric_names=["IntegrationLatency"],
        as_summary=True,
    )
    request = parse_metrics_requests(data)[0]
    dp = request.resource_metrics[0].scope_metrics[0].metrics[0].summary.data_points[0]
    # 1.5 is not a valid quantile: it checks malformed input is ignored rather
    # than emitted as a bogus _p150 series
    for quantile, value in [(0.5, 20.0), (0.95, 38.0), (0.999, 39.9), (1.5, 99.0)]:
        q = dp.quantile_values.add()
        q.quantile = quantile
        q.value = value

    transform_request(request)

    metrics = {m.name: m for m in request.resource_metrics[0].scope_metrics[0].metrics}
    expected_values = {
        "aws_apigateway_integration_latency_sum": 100.0,
        "aws_apigateway_integration_latency_sample_count": 4.0,
        "aws_apigateway_integration_latency_min": 10.0,
        "aws_apigateway_integration_latency_max": 40.0,
        "aws_apigateway_integration_latency_avg": 25.0,
        "aws_apigateway_integration_latency_p50": 20.0,
        "aws_apigateway_integration_latency_p95": 38.0,
        "aws_apigateway_integration_latency_p99_9": 39.9,
    }
    assert set(metrics) == set(expected_values)
    for name, expected in expected_values.items():
        assert metrics[name].gauge.data_points[0].as_double == expected


@pytest.mark.parametrize(
    ("quantile", "expected"),
    [
        (0.5, "p50"),
        (0.95, "p95"),
        (0.99, "p99"),
        (0.999, "p99_9"),
        (0.9999, "p99_99"),
        (0.001, "p0_1"),
        # quantile * 100 is inexact for these, e.g. 0.29 * 100 = 28.999999999999996
        (0.07, "p7"),
        (0.29, "p29"),
    ],
)
def test_percentile_suffix(quantile, expected):
    """Quantiles are named as prometheus-safe percentile suffixes."""
    from otel_cw_metrics_python.function import percentile_suffix

    assert percentile_suffix(quantile) == expected


def test_to_prometheus_passes_through_non_summary(monkeypatch):
    """Non-summary metrics are left as-is in prom mode."""
    import otel_cw_metrics_python.function as function
    from otel_cw_metrics_python.function import (
        parse_metrics_requests,
        transform_request,
    )

    monkeypatch.setattr(function, "METRIC_FORMAT", "prom")

    data = create_synthetic_metrics(metric_names=["CPUUtilization"])
    request = parse_metrics_requests(data)[0]

    transform_request(request)

    metrics = request.resource_metrics[0].scope_metrics[0].metrics
    assert len(metrics) == 1
    assert metrics[0].name == "AWS/EC2/CPUUtilization"
    assert len(metrics[0].gauge.data_points) == 1


def test_aws_format_keeps_summary_metrics(monkeypatch):
    """In aws format, summary metrics pass through unrewritten with dimensions expanded."""
    import otel_cw_metrics_python.function as function
    from otel_cw_metrics_python.function import (
        parse_metrics_requests,
        transform_request,
    )

    monkeypatch.setattr(function, "METRIC_FORMAT", "aws")

    data = create_synthetic_metrics(
        namespace="AWS/ECS",
        metric_names=["LiveTaskCount"],
        dimensions={"ClusterName": "fargate", "ServiceName": "squid"},
        as_summary=True,
    )
    request = parse_metrics_requests(data)[0]

    transform_request(request)

    metrics = request.resource_metrics[0].scope_metrics[0].metrics
    assert len(metrics) == 1
    assert metrics[0].name == "AWS/ECS/LiveTaskCount"

    dps = metrics[0].summary.data_points
    assert len(dps) == 1
    assert dps[0].sum == 100.0
    assert dps[0].count == 4

    attrs = {attr.key: attr.value.string_value for attr in dps[0].attributes}
    assert attrs["ClusterName"] == "fargate"
    assert attrs["ServiceName"] == "squid"
    assert "Dimensions" not in attrs
    assert "MetricName" not in attrs


def test_keep_metrics_filter(monkeypatch):
    """When keep_metrics is set, only matching series survive."""
    import re as re_mod

    import otel_cw_metrics_python.function as function
    from otel_cw_metrics_python.function import (
        parse_metrics_requests,
        transform_request,
    )

    monkeypatch.setattr(function, "METRIC_FORMAT", "prom")
    monkeypatch.setattr(function, "KEEP_METRICS_REGEX", re_mod.compile(r"_sum$|_avg$"))

    data = create_synthetic_metrics(
        namespace="AWS/ECS", metric_names=["LiveTaskCount"], as_summary=True
    )
    request = parse_metrics_requests(data)[0]

    transform_request(request)

    names = {m.name for m in request.resource_metrics[0].scope_metrics[0].metrics}
    assert names == {
        "aws_ecs_svc_live_task_count_sum",
        "aws_ecs_svc_live_task_count_avg",
    }


def test_remove_metrics_filter(monkeypatch):
    """When remove_metrics is set, matching series are dropped."""
    import re as re_mod

    import otel_cw_metrics_python.function as function
    from otel_cw_metrics_python.function import (
        parse_metrics_requests,
        transform_request,
    )

    monkeypatch.setattr(function, "METRIC_FORMAT", "prom")
    monkeypatch.setattr(
        function, "EXCLUDE_METRICS_REGEX", re_mod.compile(r"_sample_count$")
    )

    data = create_synthetic_metrics(
        namespace="AWS/ECS", metric_names=["LiveTaskCount"], as_summary=True
    )
    request = parse_metrics_requests(data)[0]

    transform_request(request)

    names = {m.name for m in request.resource_metrics[0].scope_metrics[0].metrics}
    assert names == {
        "aws_ecs_svc_live_task_count_sum",
        "aws_ecs_svc_live_task_count_min",
        "aws_ecs_svc_live_task_count_max",
        "aws_ecs_svc_live_task_count_avg",
    }


def test_keep_and_remove_filters_combined(monkeypatch):
    """A metric must match keep_metrics and not match remove_metrics."""
    import re as re_mod

    import otel_cw_metrics_python.function as function
    from otel_cw_metrics_python.function import (
        parse_metrics_requests,
        transform_request,
    )

    monkeypatch.setattr(function, "METRIC_FORMAT", "prom")
    monkeypatch.setattr(
        function, "KEEP_METRICS_REGEX", re_mod.compile(r"live_task_count")
    )
    monkeypatch.setattr(
        function, "EXCLUDE_METRICS_REGEX", re_mod.compile(r"_min$|_max$")
    )

    data = create_synthetic_metrics(
        namespace="AWS/ECS", metric_names=["LiveTaskCount"], as_summary=True
    )
    request = parse_metrics_requests(data)[0]

    transform_request(request)

    names = {m.name for m in request.resource_metrics[0].scope_metrics[0].metrics}
    assert names == {
        "aws_ecs_svc_live_task_count_sum",
        "aws_ecs_svc_live_task_count_sample_count",
        "aws_ecs_svc_live_task_count_avg",
    }


def test_filters_apply_to_aws_format(monkeypatch):
    """Filters run on the stripped names in aws format too."""
    import re as re_mod

    import otel_cw_metrics_python.function as function
    from otel_cw_metrics_python.function import (
        parse_metrics_requests,
        transform_request,
    )

    monkeypatch.setattr(function, "METRIC_FORMAT", "aws")
    monkeypatch.setattr(
        function, "EXCLUDE_METRICS_REGEX", re_mod.compile(r"^AWS/EC2/Network")
    )

    data = create_synthetic_metrics(
        metric_names=["CPUUtilization", "NetworkIn", "NetworkOut"]
    )
    request = parse_metrics_requests(data)[0]

    transform_request(request)

    names = [m.name for m in request.resource_metrics[0].scope_metrics[0].metrics]
    assert names == ["AWS/EC2/CPUUtilization"]


def test_record_discarded_when_all_metrics_filtered(monkeypatch, synthetic_record):
    """A record whose metrics are all filtered out is dropped without calling the endpoint."""
    import re as re_mod
    from unittest.mock import MagicMock

    import otel_cw_metrics_python.function as function
    from otel_cw_metrics_python.function import handler

    monkeypatch.setattr(function, "OTLP_ENDPOINT", "grpcs://collector.example.com:4317")
    monkeypatch.setattr(
        function, "KEEP_METRICS_REGEX", re_mod.compile(r"^will_never_match$")
    )

    stub = MagicMock()
    monkeypatch.setattr(function, "get_stub", lambda: stub)
    monkeypatch.setattr(function, "emit_forwarder_metrics", lambda *a, **kw: None)

    event = {
        "records": [
            {"recordId": "filtered-1", "data": synthetic_record},
        ]
    }

    result = handler(event, None)

    assert result["records"][0]["result"] == "Dropped"
    stub.Export.assert_not_called()


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
            "grpcs://collector.example.com:4318",
            "https://collector.example.com:4318/v1/metrics",
        ),
        ("collector.example.com:4318", "https://collector.example.com:4318/v1/metrics"),
        (
            "https://collector.example.com/otlp",
            "https://collector.example.com/otlp/v1/metrics",
        ),
        (
            "https://collector.example.com/v1/metrics",
            "https://collector.example.com/v1/metrics",
        ),
    ],
)
def test_http_metrics_url(monkeypatch, endpoint, expected_url):
    """The http/protobuf URL gets /v1/metrics appended unless already present."""
    import otel_cw_metrics_python.function as function
    from otel_cw_metrics_python.function import http_metrics_url

    monkeypatch.setattr(function, "OTLP_ENDPOINT", endpoint)

    assert http_metrics_url() == expected_url


def test_http_protobuf_export(monkeypatch, synthetic_record):
    """With OTLP_PROTOCOL=http/protobuf the request is POSTed as gzipped protobuf."""
    import gzip
    from unittest.mock import MagicMock

    import otel_cw_metrics_python.function as function
    from otel_cw_metrics_python.function import send_to_otlp

    monkeypatch.setattr(function, "OTLP_ENDPOINT", "https://collector.example.com:4318")
    monkeypatch.setattr(function, "OTLP_PROTOCOL", "http/protobuf")
    monkeypatch.setattr(function, "AUTH_TOKEN_MAP", {"default": "sekret"})
    monkeypatch.setattr(function, "ATTRIBUTE_AUTH_TOKEN_MAPPINGS", [])

    response_cm = MagicMock()
    response_cm.__enter__.return_value.read.return_value = b""

    with patch("urllib.request.urlopen", return_value=response_cm) as mock_urlopen:
        assert send_to_otlp(base64.b64decode(synthetic_record)) is True

        mock_urlopen.assert_called_once()
        http_request = mock_urlopen.call_args[0][0]

        assert http_request.full_url == "https://collector.example.com:4318/v1/metrics"
        assert http_request.get_method() == "POST"
        assert http_request.get_header("Content-type") == "application/x-protobuf"
        assert http_request.get_header("Content-encoding") == "gzip"
        assert http_request.get_header("Authorization") == "Bearer sekret"

        sent = metrics_service_pb2.ExportMetricsServiceRequest()
        sent.ParseFromString(gzip.decompress(http_request.data))
        assert len(sent.resource_metrics) == 1


def test_http_protobuf_export_failure_retries(monkeypatch, synthetic_record):
    """Persistent HTTP failures are retried then fail the record."""
    import urllib.error

    import otel_cw_metrics_python.function as function
    from otel_cw_metrics_python.function import send_to_otlp

    monkeypatch.setattr(function, "OTLP_ENDPOINT", "https://collector.example.com:4318")
    monkeypatch.setattr(function, "OTLP_PROTOCOL", "http/protobuf")
    monkeypatch.setattr(function, "HTTP_RETRY_BACKOFF_SECONDS", 0)

    with patch(
        "urllib.request.urlopen",
        side_effect=urllib.error.URLError("connection refused"),
    ) as mock_urlopen:
        assert send_to_otlp(base64.b64decode(synthetic_record)) is False
        assert mock_urlopen.call_count == function.HTTP_RETRY_ATTEMPTS


def test_strip_amazonaws_prefix(metric_format):
    """The amazonaws.com/ metric name prefix is always removed."""
    from otel_cw_metrics_python.function import (
        parse_metrics_requests,
        transform_request,
    )

    data = create_synthetic_metrics(namespace="AWS/EC2", metric_names=["EBSReadBytes"])
    request = parse_metrics_requests(data)[0]

    transform_request(request)

    metric = request.resource_metrics[0].scope_metrics[0].metrics[0]
    assert metric.name == "AWS/EC2/EBSReadBytes"

    # applying it twice is harmless
    transform_request(request)
    assert metric.name == "AWS/EC2/EBSReadBytes"


def test_parse_multiple_concatenated_messages():
    """A single Firehose record can contain several length-prefixed messages."""
    from otel_cw_metrics_python.function import parse_metrics_requests

    data = (
        create_synthetic_metrics(namespace="AWS/EC2", metric_names=["CPUUtilization"])
        + create_synthetic_metrics(
            namespace="AWS/ECS", metric_names=["MemoryUtilization", "CPUUtilization"]
        )
        + create_synthetic_metrics(namespace="AWS/Lambda", metric_names=["Errors"])
    )

    requests = parse_metrics_requests(data)

    assert len(requests) == 3
    metric_counts = [
        sum(len(sm.metrics) for rm in r.resource_metrics for sm in rm.scope_metrics)
        for r in requests
    ]
    assert metric_counts == [1, 2, 1]


def test_parse_truncated_record_raises():
    """A record cut short mid-message should raise rather than parse garbage."""
    from otel_cw_metrics_python.function import parse_metrics_requests

    data = create_synthetic_metrics()

    with pytest.raises(ValueError, match="exceeds record size"):
        parse_metrics_requests(data[:-5])


def test_handler_fails_fast_when_deadline_close(synthetic_record, caplog):
    """When the Lambda deadline is nearly reached, records fail without calling the endpoint."""
    from otel_cw_metrics_python.function import handler

    context = SimpleNamespace(get_remaining_time_in_millis=lambda: 1000)

    event = {
        "records": [
            {"recordId": "synthetic-1\r\nforged log entry", "data": synthetic_record},
        ]
    }

    with patch("otel_cw_metrics_python.function.send_to_otlp") as mock_send:
        result = handler(event, context)

        mock_send.assert_not_called()
        assert result["records"][0]["result"] == "ProcessingFailed"
        assert result["records"][0]["recordId"] == "synthetic-1\r\nforged log entry"
        assert "synthetic-1forgedlogentry" in caplog.text
        assert "forged log entry" not in caplog.text


def test_sanitize_for_log_keeps_matched_chars_and_caps_length():
    from otel_cw_metrics_python.function import sanitize_for_log

    assert sanitize_for_log("record\n_2!?/") == "record_2/"
    assert sanitize_for_log("x" * 130) == "x" * 128


@pytest.mark.parametrize("value", ["", "\n\r\x1b!?", None, 123])
def test_sanitize_for_log_returns_invalid_when_no_chars_match(value):
    from otel_cw_metrics_python.function import sanitize_for_log

    assert sanitize_for_log(value) == "<invalid>"


def test_handler_passes_capped_timeout(synthetic_record):
    """The per-call timeout is capped by the remaining Lambda time."""
    from otel_cw_metrics_python.function import handler

    context = SimpleNamespace(get_remaining_time_in_millis=lambda: 80_000)

    event = {
        "records": [
            {"recordId": "synthetic-1", "data": synthetic_record},
        ]
    }

    with patch("otel_cw_metrics_python.function.send_to_otlp") as mock_send:
        mock_send.return_value = True

        result = handler(event, context)

        assert result["records"][0]["result"] == "Dropped"
        timeout = mock_send.call_args[0][1]
        assert timeout == pytest.approx(60.0)


@pytest.mark.parametrize(
    ("before", "expected"),
    [
        ("AWS/EC2/CPUUtilization", "aws_ec2_cpu_utilization"),
        ("SomeMetricXML", "some_metric_xml"),
        (".AWS/...SomeMetricXML", "aws_some_metric_xml"),
        ("anotherMetricName.", "another_metric_name"),
        ("VolumeBytes", "volume_bytes"),
        ("LiveTaskCount", "live_task_count"),
        ("EC2", "ec2"),
        ("HTTPCode_Target_4XX_Count", "http_code_target_4xx_count"),
        ("4XXError", "4xx_error"),
        ("5XXError", "5xx_error"),
        ("mem_used_percent", "mem_used_percent"),
        ("already_snake_case", "already_snake_case"),
        ("AWS/lambda", "aws_lambda"),
        ("...", ""),
    ],
)
def test_prom_name(before, expected):
    """Test the prom_name function."""
    from otel_cw_metrics_python.function import prom_name

    actual = prom_name(before)
    assert actual == expected


@pytest.mark.parametrize(
    ("namespace", "metric_name", "expected"),
    [
        # aliased namespaces use the short service name
        ("AWS/ApplicationELB", "RequestCount", "aws_alb_request_count"),
        ("AWS/NetworkELB", "ActiveFlowCount", "aws_nlb_active_flow_count"),
        ("AWS/ECS", "LiveTaskCount", "aws_ecs_svc_live_task_count"),
        ("AWS/States", "ExecutionsFailed", "aws_sfn_executions_failed"),
        ("AWS/ElasticMapReduce", "AppsRunning", "aws_emr_apps_running"),
        ("AWS/CertificateManager", "DaysToExpiry", "aws_acm_days_to_expiry"),
        (
            "ECS/ContainerInsights",
            "CpuUtilized",
            "aws_ecs_containerinsights_cpu_utilized",
        ),
        ("CWAgent", "mem_used_percent", "aws_cwagent_mem_used_percent"),
        # unknown namespaces fall back to prom_name
        ("MyApp/Custom", "SomeMetric", "aws_my_app_custom_some_metric"),
    ],
)
def test_prom_base_name_service_aliases(namespace, metric_name, expected):
    """Namespaces are shortened to their service alias in prom series names."""
    from otel_cw_metrics_python.function import _prom_base_name

    assert _prom_base_name(namespace, f"{namespace}/{metric_name}") == expected


# ---------------------------------------------------------------------------
# Instrumentation tests
# ---------------------------------------------------------------------------
#


def test_build_forwarder_metrics_request():
    """Operational metrics request has the expected structure."""
    from otel_cw_metrics_python.function import _build_forwarder_metrics_request

    request = _build_forwarder_metrics_request(
        records_processed=3, records_failed=1, export_duration_ms=42.0
    )

    assert len(request.resource_metrics) == 1
    rm = request.resource_metrics[0]
    res_attrs = {a.key: a.value.string_value for a in rm.resource.attributes}
    assert res_attrs["cloud.provider"] == "aws"
    assert "service.name" in res_attrs

    sm = rm.scope_metrics[0]
    assert sm.scope.name == "otel_cw_metrics_python"
    assert len(sm.metrics) == 3


def test_handler_emits_forwarder_metrics(synthetic_record):
    """The handler calls emit_forwarder_metrics with correct stats."""
    from otel_cw_metrics_python.function import handler

    event = {"records": [{"recordId": "r1", "data": synthetic_record}]}

    with (
        patch("otel_cw_metrics_python.function.send_to_otlp") as mock_send,
        patch("otel_cw_metrics_python.function.emit_forwarder_metrics") as mock_emit,
    ):
        mock_send.return_value = True
        handler(event, None)

        mock_emit.assert_called_once()
        args = mock_emit.call_args
        assert args[0][0] == 1  # records_processed
        assert args[0][1] == 0  # records_failed
