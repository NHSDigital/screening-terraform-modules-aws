import json
import logging
import os
import re
from typing import Any

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

LOG_GROUP_PREFIXES = json.loads(os.environ.get("LOG_GROUP_PREFIXES", "[]"))
PREFIX_FILTER_PATTERNS = json.loads(
    os.environ.get("PREFIX_FILTER_PATTERNS", "{}")
)
PREFIX_EXCLUDE_REGEXES = {
    prefix: [re.compile(pattern) for pattern in patterns]
    for prefix, patterns in json.loads(
        os.environ.get("PREFIX_EXCLUDE_REGEXES", "{}")
    ).items()
}
DESTINATION_ARN = os.environ.get("DESTINATION_ARN", "")
SUBSCRIPTION_ROLE_ARN = os.environ.get("SUBSCRIPTION_ROLE_ARN", "")
FILTER_NAME = os.environ.get("FILTER_NAME", "")
FILTER_PATTERN = os.environ.get("FILTER_PATTERN", "")
_logs_client = None


def _client():
    global _logs_client
    if _logs_client is None:
        _logs_client = boto3.client("logs")
    return _logs_client


def _matching_log_group(name: str) -> bool:
    matching_prefixes = [prefix for prefix in LOG_GROUP_PREFIXES if name.startswith(prefix)]
    if not matching_prefixes:
        return False
    prefix = max(matching_prefixes, key=len)
    return not any(pattern.search(name) for pattern in PREFIX_EXCLUDE_REGEXES.get(prefix, []))


def _filter_pattern_for_log_group(name: str) -> str:
    matching_prefixes = [prefix for prefix in LOG_GROUP_PREFIXES if name.startswith(prefix)]
    if not matching_prefixes:
        return FILTER_PATTERN
    prefix = max(matching_prefixes, key=len)
    return PREFIX_FILTER_PATTERNS.get(prefix, FILTER_PATTERN)


def handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    log_group_name = (
        event.get("detail", {})
        .get("requestParameters", {})
        .get("logGroupName")
    )
    if not isinstance(log_group_name, str) or not log_group_name:
        logger.info("Ignoring event without a log group name")
        return {"subscribed": False}
    if not _matching_log_group(log_group_name):
        return {"subscribed": False}
    filter_pattern = _filter_pattern_for_log_group(log_group_name)

    existing_filters = _client().describe_subscription_filters(
        logGroupName=log_group_name
    ).get("subscriptionFilters", [])
    existing = next(
        (item for item in existing_filters if item.get("filterName") == FILTER_NAME),
        None,
    )
    if existing is not None:
        matches = (
            existing.get("destinationArn") == DESTINATION_ARN
            and existing.get("roleArn") == SUBSCRIPTION_ROLE_ARN
            and existing.get("filterPattern", "") == filter_pattern
        )
        if matches:
            return {"subscribed": True, "already_configured": True}
        raise RuntimeError(
            "A subscription filter with the configured name has different settings"
        )

    _client().put_subscription_filter(
        logGroupName=log_group_name,
        filterName=FILTER_NAME,
        filterPattern=filter_pattern,
        destinationArn=DESTINATION_ARN,
        roleArn=SUBSCRIPTION_ROLE_ARN,
    )
    logger.info("Created OTLP subscription for matching log group")
    return {"subscribed": True, "already_configured": False}
