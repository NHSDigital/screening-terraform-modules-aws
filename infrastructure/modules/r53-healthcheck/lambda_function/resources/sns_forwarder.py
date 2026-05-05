import json
import logging
import boto3


class SNSForwarder:

    sns_client = None

    ALARM_NAME = "AlarmName"
    NEW_STATE_VALUE = "NewStateValue"
    NEW_STATE_REASON = "NewStateReason"

    def __init__(self, sns_client, target_topic_arn):
        self.sns_client = sns_client
        self.target_topic_arn = target_topic_arn
        logging.getLogger().setLevel(logging.INFO)

    def forward_message(self, msg):
        data = self.extract_record(msg)
        logging.info("data : {}".format(data))
        return self.send(data)

    def extract_record(self, msg):
        data = {}
        json_msg = json.loads(msg)
        data[self.ALARM_NAME] = json_msg[self.ALARM_NAME]
        data[self.NEW_STATE_VALUE] = json_msg[self.NEW_STATE_VALUE]
        data[self.NEW_STATE_REASON] = json_msg[self.NEW_STATE_REASON]

        return data

    def send(self, data):
        msg_to_send = {
            self.ALARM_NAME: data[self.ALARM_NAME],
            self.NEW_STATE_VALUE: data[self.NEW_STATE_VALUE],
            self.NEW_STATE_REASON: data[self.NEW_STATE_REASON],
        }

        resp = self.sns_client.publish(
            TargetArn=self.target_topic_arn,
            Message=json.dumps({"default": json.dumps(msg_to_send)}),
            Subject=data[self.ALARM_NAME],
            MessageStructure="json",
        )
        logging.info("notification sent to SNS")
        logging.info("SNS response : {}".format(resp))

        return {"statusCode": 200, "body": json.dumps(resp)}
