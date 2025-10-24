# S3 Module Outputs


# Raw Data Bucket
output "raw_data_bucket_id" {
  description = "The name of the raw data bucket"
  value       = aws_s3_bucket.raw_data.id
}

output "raw_data_bucket_arn" {
  description = "The ARN of the raw data bucket"
  value       = aws_s3_bucket.raw_data.arn
}

output "raw_data_bucket_domain_name" {
  description = "The domain name of the raw data bucket"
  value       = aws_s3_bucket.raw_data.bucket_domain_name
}

output "raw_data_bucket_regional_domain_name" {
  description = "The regional domain name of the raw data bucket"
  value       = aws_s3_bucket.raw_data.bucket_regional_domain_name
}

output "raw_data_bucket_region" {
  description = "The AWS region this bucket resides in"
  value       = aws_s3_bucket.raw_data.region
}

# Processed Data Bucket
output "processed_data_bucket_id" {
  description = "The name of the processed data bucket"
  value       = aws_s3_bucket.processed_data.id
}

output "processed_data_bucket_arn" {
  description = "The ARN of the processed data bucket"
  value       = aws_s3_bucket.processed_data.arn
}

output "processed_data_bucket_domain_name" {
  description = "The domain name of the processed data bucket"
  value       = aws_s3_bucket.processed_data.bucket_domain_name
}

output "processed_data_bucket_regional_domain_name" {
  description = "The regional domain name of the processed data bucket"
  value       = aws_s3_bucket.processed_data.bucket_regional_domain_name
}

output "processed_data_bucket_region" {
  description = "The AWS region this bucket resides in"
  value       = aws_s3_bucket.processed_data.region
}

# Models Bucket
output "models_bucket_id" {
  description = "The name of the models bucket"
  value       = aws_s3_bucket.models.id
}

output "models_bucket_arn" {
  description = "The ARN of the models bucket"
  value       = aws_s3_bucket.models.arn
}

output "models_bucket_domain_name" {
  description = "The domain name of the models bucket"
  value       = aws_s3_bucket.models.bucket_domain_name
}

output "models_bucket_regional_domain_name" {
  description = "The regional domain name of the models bucket"
  value       = aws_s3_bucket.models.bucket_regional_domain_name
}

output "models_bucket_region" {
  description = "The AWS region this bucket resides in"
  value       = aws_s3_bucket.models.region
}

# Logs Bucket (if enabled)
output "logs_bucket_id" {
  description = "The name of the logs bucket"
  value       = try(aws_s3_bucket.logs[0].id, "")
}

output "logs_bucket_arn" {
  description = "The ARN of the logs bucket"
  value       = try(aws_s3_bucket.logs[0].arn, "")
}

# All Buckets Map
output "all_buckets" {
  description = "Map of all bucket names to their IDs"
  value = {
    raw_data       = aws_s3_bucket.raw_data.id
    processed_data = aws_s3_bucket.processed_data.id
    models         = aws_s3_bucket.models.id
    logs           = try(aws_s3_bucket.logs[0].id, null)
  }
}

output "all_bucket_arns" {
  description = "Map of all bucket names to their ARNs"
  value = {
    raw_data       = aws_s3_bucket.raw_data.arn
    processed_data = aws_s3_bucket.processed_data.arn
    models         = aws_s3_bucket.models.arn
    logs           = try(aws_s3_bucket.logs[0].arn, null)
  }
}

# IAM Role ARNs
output "replication_role_arn" {
  description = "ARN of the replication IAM role"
  value       = try(aws_iam_role.replication[0].arn, "")
}

# Versioning Status
output "versioning_status" {
  description = "Versioning status for each bucket"
  value = {
    raw_data       = aws_s3_bucket_versioning.raw_data.versioning_configuration[0].status
    processed_data = aws_s3_bucket_versioning.processed_data.versioning_configuration[0].status
    models         = aws_s3_bucket_versioning.models.versioning_configuration[0].status
  }
}

# Encryption Status
output "encryption_enabled" {
  description = "Whether encryption is enabled for the buckets"
  value       = var.enable_encryption
}

output "encryption_algorithm" {
  description = "Encryption algorithm used for the buckets"
  value       = var.sse_algorithm
}

# Transfer Acceleration
output "transfer_acceleration_enabled" {
  description = "Whether transfer acceleration is enabled"
  value       = var.enable_transfer_acceleration
}

output "transfer_acceleration_endpoints" {
  description = "Transfer acceleration endpoints for buckets"
  value = var.enable_transfer_acceleration ? {
    raw_data       = "${aws_s3_bucket.raw_data.id}.s3-accelerate.amazonaws.com"
    processed_data = "${aws_s3_bucket.processed_data.id}.s3-accelerate.amazonaws.com"
    models         = "${aws_s3_bucket.models.id}.s3-accelerate.amazonaws.com"
  } : {}
}

# Lifecycle Rules
output "lifecycle_rules_configured" {
  description = "Whether lifecycle rules are configured for each bucket"
  value = {
    raw_data       = length(var.raw_data_lifecycle_rules) > 0
    processed_data = length(var.processed_data_lifecycle_rules) > 0
    models         = length(var.models_lifecycle_rules) > 0
  }
}

# Public Access Block
output "public_access_blocked" {
  description = "Whether public access is blocked for the buckets"
  value       = var.enable_public_access_block
}

# Intelligent Tiering
output "intelligent_tiering_enabled" {
  description = "Whether intelligent tiering is enabled"
  value       = var.enable_intelligent_tiering
}

# Metrics
output "metrics_enabled" {
  description = "Whether CloudWatch metrics are enabled for the buckets"
  value       = var.enable_metrics
}

# Logging
output "logging_enabled" {
  description = "Whether access logging is enabled for the buckets"
  value       = var.enable_logging
}

output "logging_destination" {
  description = "Destination bucket for access logs"
  value       = var.enable_logging ? try(aws_s3_bucket.logs[0].id, var.logging_target_bucket) : ""
}

# Replication
output "replication_enabled" {
  description = "Whether cross-region replication is enabled"
  value       = var.enable_replication
}

# IAM Policy ARNs
output "read_only_policy_arn" {
  description = "ARN of the read-only IAM policy"
  value       = aws_iam_policy.read_only.arn
}

output "read_write_policy_arn" {
  description = "ARN of the read-write IAM policy"
  value       = aws_iam_policy.read_write.arn
}

output "admin_policy_arn" {
  description = "ARN of the admin IAM policy"
  value       = aws_iam_policy.admin.arn
}

# Tags
output "bucket_tags" {
  description = "Tags applied to each bucket"
  value = {
    raw_data       = aws_s3_bucket.raw_data.tags
    processed_data = aws_s3_bucket.processed_data.tags
    models         = aws_s3_bucket.models.tags
  }
}