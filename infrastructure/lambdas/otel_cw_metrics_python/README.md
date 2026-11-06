# OTEL CloudWatch Metrics Transformer Lambda

This Lambda function receives CloudWatch Metric Stream records, transforms them into
OpenTelemetry-friendly metrics, and forwards the result to an OTLP collector endpoint.
It is used as the in-flight transformer in the CloudWatch metrics pipeline for this
repository.

## What it does

The handler in `function.py` is responsible for:

- parsing one or more length-prefixed CloudWatch Metric Stream protocol buffer messages from a
  Firehose record
- converting metric names to either:
  - `prom` format, for Prometheus-style series names, or
  - `aws` format, for pass-through CloudWatch OTLP metrics
- expanding CloudWatch `Dimensions` into top-level metric attributes
- applying optional keep/exclude filters to the final metric names
- selecting per-request auth tokens from resource attributes via named token
  maps and `OTEL_ATTRIBUTE_AUTH_TOKEN_MAP` selectors
- exporting the transformed metrics to an OTLP endpoint over gRPC or HTTP/protobuf
- emitting best-effort forwarder instrumentation metrics
  (`forwarder.records.processed`, `forwarder.records.failed`,
  `forwarder.export.duration`)

## Environment variables

| Variable | Required | Default | Description                                                                                    |
|---|---|---|------------------------------------------------------------------------------------------------|
| `OTLP_ENDPOINT` | **yes** | — | Collector endpoint (e.g. `https://collector:4317`)                                             |
| `OTLP_PROTOCOL` | no | `grpc` | `grpc` or `http/protobuf`                                                                      |
| `OTLP_AUTH_TOKEN_SECRET_ARN_MAP` | recommended | — | JSON object of named Secrets Manager ARNs; values are fetched at runtime and cached for up to five minutes |
| `OTLP_AUTH_TOKEN` | legacy only | — | Direct plaintext Bearer token; do not use in Terraform-managed deployments |
| `OTLP_AUTH_TOKEN_MAP` | legacy only | — | JSON object of plaintext named tokens; do not use in Terraform-managed deployments |
| `OTEL_ATTRIBUTE_AUTH_TOKEN_MAP` | no | — | JSON object mapping `resource.attr=regex` selectors to names from `OTLP_AUTH_TOKEN_SECRET_ARN_MAP` |
| `METRIC_FORMAT` | no | `prom` | `prom` rewrites metrics into Prometheus-style series; `aws` passes them through                |
| `KEEP_METRICS_REGEX` | no | — | When set, only metrics whose final name matches are kept                                       |
| `EXCLUDE_METRICS_REGEX` | no | — | When set, metrics whose final name matches are dropped                                         |
| `OTEL_RESOURCE_ATTRIBUTES` | no | — | Extra resource attributes (`key=value,key=value`)                                              |
| `AWS_REGION` | auto | `eu-west-2` | Set automatically in the Lambda runtime                                                        |

### Auth token selection

Use exactly one of these configuration modes:

- `OTLP_AUTH_TOKEN_SECRET_ARN_MAP` (named secret ARNs; used by screening Terraform modules)
- `OTLP_AUTH_TOKEN` or `OTLP_AUTH_TOKEN_MAP` (legacy direct values for non-Terraform local use only)

Setting both — or neither — is invalid.

The `default` entry is required. Secret values are retrieved from Secrets
Manager only when selected, cached for at most five minutes, and never written
to Lambda environment variables by the screening modules. The Lambda execution
role needs `secretsmanager:GetSecretValue` on the configured secret ARNs and,
for customer-managed keys, narrowly scoped `kms:Decrypt` permission.

`OTEL_ATTRIBUTE_AUTH_TOKEN_MAP` selects auth tokens from the resource
attributes of each `ResourceMetrics` in a request. Keys are
`resource.attribute.key=regex` selectors, values are **token names** from
`OTLP_AUTH_TOKEN_SECRET_ARN_MAP`. If no selector matches, `default` is used; when
multiple selectors match, the last one wins.

The Lambda groups the `ResourceMetrics` in each request by resolved token and
exports one request per token.

At startup, the Lambda validates that every selector value exists as a key in
the configured token map.

Example token map:

```json
OTLP_AUTH_TOKEN_SECRET_ARN_MAP={"default":"arn:aws:secretsmanager:eu-west-2:123456789012:secret:otel-default-AbCdEf","pid":"arn:aws:secretsmanager:eu-west-2:123456789012:secret:otel-pid-GhIjKl"}
```

Example `OTEL_ATTRIBUTE_AUTH_TOKEN_MAP` JSON:

```json
{
  "deployment.environment.name=.*-prod": "pid"
}
```

## How it is deployed

Deploy with the screening Terraform composition at
`infrastructure/modules/cloudwatch-metrics-to-otlp`. Terraform packages this
screening-owned source directory and passes secret ARNs, never secret values,
to the Lambda.

This forwarder is a screening-repository-owned port of the ODIN Python
implementation. The MIT licence notice is retained in
`infrastructure/lambdas/LICENSE.md`.

## Local development

The Lambda source lives alongside its tests in this directory:

- `function.py`
- `function_tests.py`
- `requirements.txt`

Run the tests from the repository root with:

```bash
PYTHONPATH=infrastructure/lambdas mise x -- pytest -q infrastructure/lambdas/otel_cw_metrics_python/function_tests.py
```

## Building the deployment zip

The screening Lambda wrapper packages this directory and installs its pinned
`requirements.txt` dependencies during deployment. Its Python runtime and
architecture must be compatible with the configured Lambda runtime.
