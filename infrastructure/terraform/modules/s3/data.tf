# Data sources for S3 module

# Current AWS account ID
data "aws_caller_identity" "current" {}

# Current AWS region
data "aws_region" "current" {}

# Current AWS partition
data "aws_partition" "current" {}

# S3 bucket policy for ELB access logs 
data "aws_elb_service_account" "main" {}

# Canonical user ID for CloudFront
data "aws_cloudfront_log_delivery_canonical_user_id" "cloudfront" {}