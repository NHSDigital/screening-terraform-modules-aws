import logging
import boto3
import os

from resources.sns_forwarder import SNSForwarder


def lambda_handler(event, context):
    logging.getLogger().setLevel(logging.INFO)
    logging.info("event : {}".format(event))
    sns_client = boto3.client("sns", region_name="eu-west-2")
    target_topic_arn = os.environ["EU_WEST_2_SNS"]
    sns_forwarder = SNSForwarder(sns_client, target_topic_arn)
    return sns_forwarder.forward_message(event["Records"][0]["Sns"]["Message"])
