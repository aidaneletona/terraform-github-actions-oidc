# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}


# -----------------------------------------------------------------------------
# S3 KMS Encryption
# -----------------------------------------------------------------------------

resource "aws_kms_key" "s3" {
  description         = "KMS key for ${var.project} ${var.environment} S3 bucket"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "EnableIAMPermissions"
        Effect = "Allow"

        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }

        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}


resource "aws_kms_alias" "s3" {
  name          = "alias/${var.project}-${var.environment}-s3"
  target_key_id = aws_kms_key.s3.key_id
}


# -----------------------------------------------------------------------------
# Demo S3 Bucket
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "demo" {

  # checkov:skip=CKV2_AWS_62:Event notifications are not required for this demo bucket
  # checkov:skip=CKV_AWS_144:Cross-region replication is outside the scope of this development environment

  bucket = var.demo_bucket

  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = var.demo_purpose
  }
}


# Demo Bucket - KMS Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "demo" {
  bucket = aws_s3_bucket.demo.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3.arn
      sse_algorithm     = "aws:kms"
    }

    bucket_key_enabled = true
  }
}


# Demo Bucket - Versioning
resource "aws_s3_bucket_versioning" "demo" {
  bucket = aws_s3_bucket.demo.id

  versioning_configuration {
    status = "Enabled"
  }
}


# Demo Bucket - Public Access Protection
resource "aws_s3_bucket_public_access_block" "demo" {
  bucket = aws_s3_bucket.demo.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}


# Demo Bucket - Lifecycle
resource "aws_s3_bucket_lifecycle_configuration" "demo" {
  bucket = aws_s3_bucket.demo.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}


# -----------------------------------------------------------------------------
# S3 Access Logs Bucket
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "logs" {

  # checkov:skip=CKV2_AWS_62:Event notifications are not required for the access logs bucket
  # checkov:skip=CKV_AWS_144:Cross-region replication is outside the scope of this development environment

  bucket = "${var.demo_bucket}-logs"

  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "S3 access logs"
  }
}


# Logs Bucket - KMS Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3.arn
      sse_algorithm     = "aws:kms"
    }

    bucket_key_enabled = true
  }
}


# Logs Bucket - Versioning
resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}


# Logs Bucket - Public Access Protection
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# Logs Bucket - Lifecycle
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "logs-retention"
    status = "Enabled"

    filter {}

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}


# -----------------------------------------------------------------------------
# S3 Server Access Logging
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_logging" "demo" {
  bucket        = aws_s3_bucket.demo.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "access-logs/"
}
