import re
from unittest.mock import MagicMock

import pytest


@pytest.fixture
def function(monkeypatch):
    import infrastructure.lambdas.cloudwatch_log_subscription_controller.function as module

    client = MagicMock()
    monkeypatch.setattr(module, "_logs_client", client)
    monkeypatch.setattr(module, "LOG_GROUP_PREFIXES", ["/aws/lambda/app-"])
    monkeypatch.setattr(module, "DESTINATION_ARN", "arn:aws:firehose:eu-west-2:123456789012:deliverystream/test")
    monkeypatch.setattr(module, "SUBSCRIPTION_ROLE_ARN", "arn:aws:iam::123456789012:role/cw-delivery")
    monkeypatch.setattr(module, "FILTER_NAME", "otel-subscription")
    monkeypatch.setattr(module, "FILTER_PATTERN", "ERROR")
    return module, client


def test_matching_new_group_gets_subscription(function):
    module, client = function
    client.describe_subscription_filters.return_value = {"subscriptionFilters": []}

    result = module.handler(
        {"detail": {"requestParameters": {"logGroupName": "/aws/lambda/app-new"}}},
        None,
    )

    assert result == {"subscribed": True, "already_configured": False}
    client.put_subscription_filter.assert_called_once_with(
        logGroupName="/aws/lambda/app-new",
        filterName="otel-subscription",
        filterPattern="ERROR",
        destinationArn="arn:aws:firehose:eu-west-2:123456789012:deliverystream/test",
        roleArn="arn:aws:iam::123456789012:role/cw-delivery",
    )


def test_longest_prefix_selects_filter_pattern(function, monkeypatch):
    module, client = function
    client.describe_subscription_filters.return_value = {"subscriptionFilters": []}
    monkeypatch.setattr(module, "LOG_GROUP_PREFIXES", ["/aws/", "/aws/lambda/app-"])
    monkeypatch.setattr(
        module,
        "PREFIX_FILTER_PATTERNS",
        {"/aws/": "INFO", "/aws/lambda/app-": "ERROR"},
    )

    module.handler(
        {"detail": {"requestParameters": {"logGroupName": "/aws/lambda/app-new"}}},
        None,
    )

    assert client.put_subscription_filter.call_args.kwargs["filterPattern"] == "ERROR"


def test_exclusion_regex_is_scoped_to_matching_prefix(function, monkeypatch):
    module, client = function
    monkeypatch.setattr(
        module,
        "PREFIX_EXCLUDE_REGEXES",
        {"/aws/lambda/app-": [re.compile("ignored")]},
    )

    result = module.handler(
        {"detail": {"requestParameters": {"logGroupName": "/aws/lambda/app-ignored"}}},
        None,
    )

    assert result == {"subscribed": False}
    client.describe_subscription_filters.assert_not_called()


def test_non_matching_group_is_ignored(function):
    module, client = function

    result = module.handler(
        {"detail": {"requestParameters": {"logGroupName": "/aws/lambda/other"}}},
        None,
    )

    assert result == {"subscribed": False}
    client.describe_subscription_filters.assert_not_called()


def test_matching_existing_filter_is_idempotent(function):
    module, client = function
    client.describe_subscription_filters.return_value = {
        "subscriptionFilters": [
            {
                "filterName": "otel-subscription",
                "destinationArn": module.DESTINATION_ARN,
                "roleArn": module.SUBSCRIPTION_ROLE_ARN,
                "filterPattern": "ERROR",
            }
        ]
    }

    result = module.handler(
        {"detail": {"requestParameters": {"logGroupName": "/aws/lambda/app-existing"}}},
        None,
    )

    assert result == {"subscribed": True, "already_configured": True}
    client.put_subscription_filter.assert_not_called()


def test_conflicting_named_filter_fails_for_eventbridge_retry(function):
    module, client = function
    client.describe_subscription_filters.return_value = {
        "subscriptionFilters": [
            {
                "filterName": "otel-subscription",
                "destinationArn": "arn:aws:firehose:eu-west-2:123456789012:deliverystream/other",
                "roleArn": module.SUBSCRIPTION_ROLE_ARN,
                "filterPattern": "ERROR",
            }
        ]
    }

    with pytest.raises(RuntimeError, match="different settings"):
        module.handler(
            {"detail": {"requestParameters": {"logGroupName": "/aws/lambda/app-conflict"}}},
            None,
        )
