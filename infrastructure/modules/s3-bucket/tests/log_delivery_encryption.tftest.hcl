variables {
  service                                          = "test"
  environment                                      = "test"
  name                                             = "lb-logs"
  attach_lb_log_delivery_policy                    = true
  allow_lb_log_delivery_without_encryption_headers = true
  logging                                          = null
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PreserveCallerPolicy"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "arn:aws:s3:::lb-logs/*"
    }]
  })
}

run "load_balancer_delivery_keeps_encryption_denies" {
  command = plan

  assert {
    condition = can(regex(
      "logdelivery.elasticloadbalancing.amazonaws.com",
      data.aws_iam_policy_document.lb_log_delivery_encryption_exception[0].json
      )) && can(regex(
      "DenyIncorrectEncryptionHeaders",
      data.aws_iam_policy_document.lb_log_delivery_encryption_exception[0].json
      )) && can(regex(
      "PreserveCallerPolicy",
      data.aws_iam_policy_document.lb_log_delivery_encryption_exception[0].json
    ))
    error_message = "The exception policy must allow only ELB service requests to omit encryption headers and continue denying incorrect encryption headers."
  }
}
