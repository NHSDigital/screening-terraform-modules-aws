# OTEL CloudWatch Logs Forwarder Lambda

This Lambda function receives CloudWatch Logs subscription filter events, converts
them into OpenTelemetry log records, and forwards them to an OTLP collector endpoint.

## What it does

The handler in `function.py` is responsible for:

- decoding CloudWatch Logs subscription filter events (base64 + `gzip` compressed JSON)
- converting each log event into an OTLP `LogRecord` with the raw message as the body
- enriching logs with standard resource attributes:
  - `service.name` — defaults to the CloudWatch log group name
  - `cloud.provider` — `aws`
  - `cloud.region` — from the Lambda's `AWS_REGION` environment variable
  - `cloud.account.id` — from the log event's `owner` field
- adding per-record attributes: `aws.cloudwatch.log_group` and `aws.cloudwatch.log_stream`
- merging additional resource attributes from the `OTEL_RESOURCE_ATTRIBUTES` environment
  variable (comma-separated `key=value` pairs), which can override any default
- optionally applying per-log-group resource attribute overrides from
  `LOG_GROUP_RESOURCE_ATTRIBUTES` (regex selectors, with `/...` normalized to `^/...`)
- optionally extracting resource attributes from the log group name via a
  `LOG_GROUP_REGEX` named-group regex pattern
- optionally extracting per-record log attributes from each log message via:
  - `LOG_LINE_REGEX` — a named-group regex applied to the raw message text
  - `LOG_LINE_JSON_PATHS` — dot-notation paths into JSON-structured log lines
- selecting per-log-group auth tokens via named token maps and selectors
- selecting auth tokens from final resource attributes via
  `OTEL_ATTRIBUTE_AUTH_TOKEN_MAP`
- exporting the OTLP log records to an endpoint over gRPC or HTTP/protobuf
- optionally pacing OTLP pushes with a `RATE_LIMIT` (pushes per second) rate limiter
- emitting best-effort forwarder instrumentation metrics
  (`forwarder.records.processed`, `forwarder.records.failed`,
  `forwarder.export.duration`)
- skipping CloudWatch control messages gracefully

## Environment variables

| Variable | Required | Default | Description                                                                                                  |
|---|---|---|--------------------------------------------------------------------------------------------------------------|
| `OTLP_ENDPOINT` | **yes** | — | Collector endpoint (e.g. `https://collector:4317`)                                                           |
| `OTLP_PROTOCOL` | no | `grpc` | `grpc` or `http/protobuf`                                                                                    |
| `OTLP_AUTH_TOKEN_SECRET_ARN_MAP` | recommended | — | JSON object of named Secrets Manager ARNs; values are fetched at runtime and cached for up to five minutes |
| `OTLP_AUTH_TOKEN_MAP` | legacy only | — | JSON object of plaintext named tokens; do not use in Terraform-managed deployments |
| `LOG_GROUP_AUTH_TOKEN_MAP` | no | — | JSON object mapping regex log-group selectors to names from `OTLP_AUTH_TOKEN_SECRET_ARN_MAP` |
| `OTLP_AUTH_TOKEN` | legacy only | — | Single plaintext Bearer token; do not use in Terraform-managed deployments |
| `LOG_GROUP_REGEX` | no | — | Regex with named groups to extract resource attributes from the log group name (see below)                   |
| `LOG_LINE_REGEX` | no | — | Regex with named groups to extract log record attributes from each log message (see below)                   |
| `LOG_LINE_JSON_PATHS` | no | — | JSON path extraction mappings for structured log lines (see below)                                           |
| `OTEL_RESOURCE_ATTRIBUTES` | no | — | Extra resource attributes (`key=value,key=value`); highest precedence                                        |
| `LOG_GROUP_RESOURCE_ATTRIBUTES` | no | — | JSON object mapping regex log-group selectors to `key=value,...` resource attributes |
| `OTEL_ATTRIBUTE_AUTH_TOKEN_MAP` | no | — | JSON object mapping `resource.attr=regex` selectors to names from `OTLP_AUTH_TOKEN_SECRET_ARN_MAP` |
| `RATE_LIMIT` | no | unlimited | Maximum OTLP pushes per second; `0`, empty, or invalid means unlimited                                       |
| `AWS_REGION` | auto | `eu-west-2` | Set automatically in the Lambda runtime                                                                      |

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

`LOG_GROUP_AUTH_TOKEN_MAP` selects auth tokens by log group. It is a JSON
object where keys are selectors and values are **token names** from
`OTLP_AUTH_TOKEN_SECRET_ARN_MAP`:

- keys are regex patterns
- if a key starts with `/`, the Lambda prepends `^` so it matches from the
  start of the log group name

If no selector matches, `default` is used.

At startup, the Lambda validates that every selector value exists as a key in
the configured token map.

`OTEL_ATTRIBUTE_AUTH_TOKEN_MAP` allows auth token selection from final
resource attributes. Keys are `resource.attribute.key=regex` selectors, values
are token names from `OTLP_AUTH_TOKEN_SECRET_ARN_MAP`.

This mapping is applied **after** log-group token selection and after resource
attribute enrichment (defaults, `LOG_GROUP_REGEX`, `OTEL_RESOURCE_ATTRIBUTES`,
and `LOG_GROUP_RESOURCE_ATTRIBUTES`), so it can override the token chosen by
`LOG_GROUP_AUTH_TOKEN_MAP`.

Example token map:

```json
OTLP_AUTH_TOKEN_SECRET_ARN_MAP={"default":"arn:aws:secretsmanager:eu-west-2:123456789012:secret:otel-default-AbCdEf","pid":"arn:aws:secretsmanager:eu-west-2:123456789012:secret:otel-pid-GhIjKl"}
```

Example `LOG_GROUP_AUTH_TOKEN_MAP` JSON:

```json
{
  "^/aws/lambda/pid-": "pid",
  "/aws/lambda/platform-api": "default"
}
```

Example `OTEL_ATTRIBUTE_AUTH_TOKEN_MAP` JSON:

```json
{
  "deployment.environment.name=.*-prod": "pid"
}
```

### `LOG_GROUP_REGEX`

A Python regex applied to the CloudWatch log group name. Named capture groups
are converted to OpenTelemetry resource attribute keys because regex group names cannot
contain dots, use **double underscores** (`__`) as the dot separator:

| Regex group name | OpenTelemetry attribute key |
|---|---|
| `service__name` | `service.name` |
| `deployment__environment__name` | `deployment.environment.name` |

Groups that don't participate in the match or capture an empty string are
silently skipped.

**Precedence** (last wins): built-in defaults → `LOG_GROUP_REGEX` → `OTEL_RESOURCE_ATTRIBUTES` → `LOG_GROUP_RESOURCE_ATTRIBUTES`.

### `LOG_GROUP_RESOURCE_ATTRIBUTES`

Optional JSON object where each key is either:

- a regex pattern
- if a key starts with `/`, the lambda prepends `^` so it matches from the
  start of the log group name

Each value is a resource attribute string in the same format as
`OTEL_RESOURCE_ATTRIBUTES` (`key=value,key=value`).

When multiple entries match the same log group, later entries overwrite earlier
ones for duplicate keys.

Example:

```json
{
  "/aws/lambda/payment-api": "service.name=payment-api,deployment.environment=prod",
  "^/aws/lambda/": "cloud.platform=aws_lambda"
}
```

**Example** — extract `service.name` and `deployment.environment.name` from log
groups like `/prod/payment-api`:

```text
LOG_GROUP_REGEX=^/(?P<deployment__environment__name>[^/]+)/(?P<service__name>.+)$
```

### `LOG_LINE_REGEX`

A Python regex applied to each log message.  Named capture groups become log
record attributes, using the same `__` → `.` convention as `LOG_GROUP_REGEX`.

Two formats are supported:

**Simple format** — a single regex string applied to all log groups:

```text
LOG_LINE_REGEX=\[(?P<severity__text>[A-Z]+)\] (?P<trace__id>[a-f0-9]+)
```

**JSON array format** — each entry has a `regex` and an optional `log_group`
regex that restricts extraction to matching log groups:

```json
[
  {"regex": "\\[(?P<severity__text>[A-Z]+)\\]"},
  {"regex": "requestId=(?P<request__id>\\S+)",
   "log_group": "^/aws/lambda/"}
]
```

Entries without a `log_group` field apply to all log groups.  The format is
auto-detected: if the value starts with `[` it is parsed as JSON, otherwise the
simple format is used.  When multiple entries match the same log line, later
entries overwrite earlier ones for the same attribute key.

### `LOG_LINE_JSON_PATHS`

Extracts attributes from JSON-structured log lines.  Two formats are supported:

**Simple format** — comma-separated `attr=json.path` pairs (applies to all log
groups):

```text
LOG_LINE_JSON_PATHS=severity.text=level,request.id=requestContext.requestId
```

**JSON array format** — each entry can include an optional `log_group` regex so
that extraction only applies to matching log groups:

```json
[
  {"attr": "severity.text", "path": "level"},
  {"attr": "request.id", "path": "requestContext.requestId",
   "log_group": "^/aws/lambda/"}
]
```

Entries without a `log_group` field apply to all log groups.  The format is
auto-detected: if the value starts with `[` it is parsed as JSON, otherwise the
simple format is used.

Paths are dot-separated object keys (`response.statusCode` resolves
`{"response": {"statusCode": 200}}`).  Non-string values are converted with
`str()`.  Lines that are not valid JSON, or paths that don't exist, are silently
skipped.

## How to use

Deploy with the screening Terraform composition at
`infrastructure/modules/cloudwatch-logs-to-otlp`. Terraform packages this
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
PYTHONPATH=infrastructure/lambdas mise x -- pytest -q infrastructure/lambdas/otel_cw_logs_python/function_tests.py
```

## Building the deployment zip

The screening Lambda wrapper packages this directory and installs its pinned
`requirements.txt` dependencies during deployment. Its Python runtime and
architecture must be compatible with the configured Lambda runtime.
