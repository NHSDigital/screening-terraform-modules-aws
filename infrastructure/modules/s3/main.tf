# tflint-ignore: terraform_unused_declarations
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.name_prefix}-${var.bucket_name}"

  tags = {
    Name = "${var.name_prefix}-${var.bucket_name}"
  }
}

resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "bucket" {
  # Check to see if the value is either null or "logging_bucket" to skip logging
  # when creating the logging bucket itself
  count         = var.logging_bucket != null && var.bucket_name != var.logging_bucket ? 1 : 0
  bucket        = aws_s3_bucket.bucket.id
  target_bucket = "${var.name_prefix}-${var.logging_bucket}"
  target_prefix = "log/${var.bucket_name}"
}

resource "aws_s3_bucket_public_access_block" "public" {
  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "access_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = var.bucket_policy
}
