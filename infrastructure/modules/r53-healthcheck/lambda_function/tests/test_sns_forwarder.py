import unittest
import json

from resources.sns_forwarder import SNSForwarder

class TestSNSForwarder(unittest.TestCase):
   
    
    def test_get_new_ticket_body(self):
        sns_forwarder  = SNSForwarder(None)

        mock_name = "mock state name"
        mock_state_value = "mock state value"
        mock_state_reason = "mock state reason"
        mock_record = self.get_mock_record(mock_name,mock_state_value,mock_state_reason)
        data = sns_forwarder.extract_record(mock_record)
    
        self.assertEqual(data[SNSForwarder.ALARM_NAME],mock_name)
        self.assertEqual(data[SNSForwarder.NEW_STATE_VALUE],mock_state_value)
        self.assertEqual(data[SNSForwarder.NEW_STATE_REASON],mock_state_reason)    
        

 ####HELPER METHODS########
    
    def get_mock_record(self,alarm_name,state_value,state_reason):
        return json.dumps({
        SNSForwarder.ALARM_NAME: alarm_name,
        SNSForwarder.NEW_STATE_VALUE: state_value,
        SNSForwarder.NEW_STATE_REASON: state_reason  
    })