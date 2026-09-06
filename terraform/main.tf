resource "aws_s3_bucket" "demo" {
    bucket = "terraform-oidc-demo-aidan"
    tags = {
        Name: var.name
        Project: var.project
        Environment: var.environment
    }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "demo" {
    bucket = aws_s3_bucket.demo.id
    rule {
        apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
        }
    }
}

resource "aws_s3_bucket_versioning" "demo" {
    bucket = aws_s3_bucket.demo.id
        versioning_configuration {
        status = "Enabled"
        }
}

resource "aws_s3_bucket_public_access_block" "demo" {
    bucket = aws_s3_bucket.demo.id 
    block_public_acls       = true
    ignore_public_acls      = true
    block_public_policy     = true
    restrict_public_buckets = true
}