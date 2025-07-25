resource "aws_kms_key" "key" {
  description             = "The key used to encrypt the data_bucket"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.name_prefix}-${var.bucket_name}"

  tags = {
    Name = "${var.name_prefix}-${var.bucket_name}"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# AWS recommended ACLs to be disabled and use bucket policy instead to control access
# resource "aws_s3_bucket_acl" "acl" {
#   bucket = aws_s3_bucket.bucket.id
#   acl    = "private"

#   depends_on = [aws_s3_bucket_ownership_controls.ownership]
# }

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

