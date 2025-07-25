
variable "exclude_extra_logging" {
  default     = false
  description = "Exclude extra logging information in the Lambda function that preprocesses the CW logs before sending to Splunk"
}

variable "firehose_splunk_url" {
  description = "URL for splunk"
  default     = "https://firehose.inputs.splunk.aws.digital.nhs.uk/services/collector"
}

variable "splunk_hec_token" {
  description = "Splunk HEC token which points to a specific log index in Splunk"
  sensitive   = true
}

variable "name_prefix" {
  description = "The account, environment etc"
  type        = string
}

variable "aws_account_id" {
  sensitive   = true
  description = "The AWS account ID"
  type        = string
}

variable "environment" {
  description = "The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD"
  type        = string
}
