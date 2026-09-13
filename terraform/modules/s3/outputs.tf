output "bucket_id" {
  value = aws_s3_bucket.demo.id
}

output "server_side_encryption_configuration_id" {
  value = aws_s3_bucket_server_side_encryption_configuration.demo.id
}


output "versioning_id" {
  value = aws_s3_bucket_versioning.demo.id
}


output "public_access_block_id" {
  value = aws_s3_bucket_public_access_block.demo.id
}





