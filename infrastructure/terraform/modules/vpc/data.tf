# Data sources for VPC module
# Fetches information about current AWS environment

# Current AWS region
data "aws_region" "current" {}

# Current AWS account ID
data "aws_caller_identity" "current" {}

# Current AWS partition
data "aws_partition" "current" {}

# Available AZs in the current region
data "aws_availability_zones" "available" {
  state = "available"
}