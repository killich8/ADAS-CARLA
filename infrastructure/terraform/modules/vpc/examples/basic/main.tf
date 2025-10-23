# test

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Use the VPC module
module "vpc_test" {
  # modules/vpc
  source = "../../"

  name        = "test-vpc"
  environment = "test"
  cidr        = "10.99.0.0/16"

  # 3 AZ max 
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  # Create 3 tiers of subnets
  public_subnets = [
    "10.99.1.0/24",
    "10.99.2.0/24",
    "10.99.3.0/24"
  ]

  private_subnets = [
    "10.99.11.0/24",
    "10.99.12.0/24",
    "10.99.13.0/24"
  ]

  database_subnets = [
    "10.99.21.0/24",
    "10.99.22.0/24",
    "10.99.23.0/24"
  ]

  # NAT Gateway settings (single NAT for test)
  enable_nat_gateway = true
  single_nat_gateway = true

  # Enable DNS
  enable_dns_hostnames = true
  enable_dns_support   = true

  # VPC endpoints
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true

  # Flow logs
  enable_flow_logs         = false
  flow_logs_retention_days = 1

  tags = {
    Terraform   = "true"
    Environment = "test"
    Purpose     = "module-testing"
  }
}

# Outputs for testing
output "vpc_id" { value = module.vpc_test.vpc_id }
output "vpc_cidr" { value = module.vpc_test.vpc_cidr_block }
output "public_subnets" { value = module.vpc_test.public_subnets }
output "private_subnets" { value = module.vpc_test.private_subnets }
output "nat_public_ips" { value = module.vpc_test.nat_public_ips }
output "database_subnet_group" { value = module.vpc_test.database_subnet_group_name }
