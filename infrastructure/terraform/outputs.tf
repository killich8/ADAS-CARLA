# Terraform outputs for ADAS-Forge infrastructure
# These values can be referenced by other tools and scripts

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

output "database_subnets" {
  description = "List of database subnet IDs"
  value       = module.vpc.database_subnets
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.vpc.natgw_ids
}

# EKS Outputs
output "eks_cluster_id" {
  description = "The name/id of the EKS cluster"
  value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
  sensitive   = false
}

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_primary_security_group_id
}

output "eks_cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = module.eks.cluster_iam_role_arn
}

output "eks_node_groups" {
  description = "Details of the EKS node groups"
  value       = module.eks.eks_managed_node_groups
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

# Configure kubectl command
output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_id}"
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_instance_endpoint
  sensitive   = false
}

output "rds_database_name" {
  description = "RDS database name"
  value       = module.rds.db_instance_name
}

output "rds_username" {
  description = "RDS master username"
  value       = module.rds.db_instance_username
  sensitive   = true
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.rds.db_instance_port
}

# S3 Outputs
output "s3_bucket_raw_data" {
  description = "S3 bucket for raw data"
  value       = module.s3_buckets["raw_data"].s3_bucket_id
}

output "s3_bucket_processed_data" {
  description = "S3 bucket for processed data"
  value       = module.s3_buckets["processed_data"].s3_bucket_id
}

output "s3_bucket_models" {
  description = "S3 bucket for ML models"
  value       = module.s3_buckets["models"].s3_bucket_id
}

output "s3_bucket_arns" {
  description = "ARNs of all S3 buckets"
  value = {
    for k, v in module.s3_buckets : k => v.s3_bucket_arn
  }
}

# ElastiCache Outputs
output "elasticache_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = module.elasticache.primary_endpoint_address
}

output "elasticache_port" {
  description = "ElastiCache Redis port"
  value       = module.elasticache.port
}

# Security Group Outputs
output "security_group_ids" {
  description = "Map of all security group IDs"
  value = {
    vpc_default = module.vpc.default_security_group_id
    eks_cluster = module.eks.cluster_primary_security_group_id
    eks_nodes   = module.eks.node_security_group_id
    rds        = module.rds.db_instance_security_group_id
    redis      = module.elasticache.security_group_id
  }
}

# Load Balancer Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = try(module.alb.lb_dns_name, "")
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = try(module.alb.lb_zone_id, "")
}

# KMS Keys
output "kms_key_ids" {
  description = "Map of KMS key IDs"
  value = {
    eks = try(module.kms_eks.key_id, "")
    rds = try(module.kms_rds.key_id, "")
    s3  = try(module.kms_s3.key_id, "")
  }
}

# CloudWatch Log Groups
output "cloudwatch_log_groups" {
  description = "Map of CloudWatch log group names"
  value = {
    eks        = "/aws/eks/${local.eks_cluster_name}/cluster"
    carla      = "/aws/adas-forge/${var.environment}/carla"
    processor  = "/aws/adas-forge/${var.environment}/processor"
    api        = "/aws/adas-forge/${var.environment}/api"
  }
}

# IAM Roles
output "iam_roles" {
  description = "Map of IAM role ARNs"
  value = {
    eks_cluster      = module.eks.cluster_iam_role_arn
    eks_node_group   = try(module.eks.eks_managed_node_groups["system"].iam_role_arn, "")
    irsa_ebs_csi     = try(module.eks.irsa_ebs_csi_role_arn, "")
    irsa_cluster_autoscaler = try(module.eks.irsa_cluster_autoscaler_role_arn, "")
  }
}

# Environment Info
output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

# Connection strings for applications
output "connection_strings" {
  description = "Connection strings for various services"
  value = {
    postgres = "postgresql://${module.rds.db_instance_username}:PASSWORD@${module.rds.db_instance_endpoint}/${module.rds.db_instance_name}"
    redis    = "redis://${module.elasticache.primary_endpoint_address}:${module.elasticache.port}"
  }
  sensitive = true
}

# Summary output for easy reference
output "summary" {
  description = "Summary of the infrastructure"
  value = {
    vpc_id              = module.vpc.vpc_id
    eks_cluster_name    = module.eks.cluster_id
    rds_endpoint        = module.rds.db_instance_endpoint
    redis_endpoint      = module.elasticache.primary_endpoint_address
    s3_buckets = {
      raw_data       = module.s3_buckets["raw_data"].s3_bucket_id
      processed_data = module.s3_buckets["processed_data"].s3_bucket_id
      models         = module.s3_buckets["models"].s3_bucket_id
    }
    load_balancer_dns = try(module.alb.lb_dns_name, "Not deployed")
  }
}