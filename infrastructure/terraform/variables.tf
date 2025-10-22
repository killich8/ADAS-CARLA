# Global variables for ADAS-CARLA infrastructure
# These can be overridden in environment-specific tfvars files

# General Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "adas-carla"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-1"
}

variable "aws_secondary_region" {
  description = "Secondary AWS region for DR"
  type        = string
  default     = "eu-central-1"
}

variable "azs" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

# Networking
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all AZs (cost optimization)"
  type        = bool
  default     = false  # false for HA in production
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway for secure connections"
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

# EKS Configuration
variable "eks_cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "eks_node_groups" {
  description = "Configuration for EKS node groups"
  type = map(object({
    instance_types = list(string)
    scaling_config = object({
      desired_size = number
      min_size     = number
      max_size     = number
    })
    disk_size    = number
    disk_type    = string
    labels       = map(string)
    taints       = list(object({
      key    = string
      value  = string
      effect = string
    }))
    tags         = map(string)
  }))
  default = {
    system = {
      instance_types = ["t3.medium"]
      scaling_config = {
        desired_size = 2
        min_size     = 1
        max_size     = 4
      }
      disk_size = 50
      disk_type = "gp3"
      labels = {
        role = "system"
      }
      taints = []
      tags   = {}
    }
    compute = {
      instance_types = ["c5.2xlarge", "c5.4xlarge"]
      scaling_config = {
        desired_size = 3
        min_size     = 1
        max_size     = 10
      }
      disk_size = 100
      disk_type = "gp3"
      labels = {
        role = "compute"
      }
      taints = []
      tags   = {}
    }
    gpu = {
      instance_types = ["g4dn.xlarge", "g4dn.2xlarge"]
      scaling_config = {
        desired_size = 1
        min_size     = 0
        max_size     = 20
      }
      disk_size = 200
      disk_type = "gp3"
      labels = {
        role = "gpu"
        "nvidia.com/gpu" = "true"
      }
      taints = [
        {
          key    = "nvidia.com/gpu"
          value  = "true"
          effect = "NoSchedule"
        }
      ]
      tags = {
        "k8s.io/accelerator" = "nvidia-tesla-t4"
      }
    }
  }
}

# RDS Configuration
variable "rds_engine" {
  description = "Database engine"
  type        = string
  default     = "postgres"
}

variable "rds_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "15.4"
}

variable "rds_instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.medium"
}

variable "rds_allocated_storage" {
  description = "Allocated storage in GBs"
  type        = number
  default     = 100
}

variable "rds_storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false  # true for production
}

variable "rds_backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "rds_backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "rds_maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

# S3 Configuration
variable "s3_buckets" {
  description = "S3 buckets to create"
  type = map(object({
    versioning = bool
    lifecycle_rules = list(object({
      id      = string
      enabled = bool
      transitions = list(object({
        days          = number
        storage_class = string
      }))
      expiration = object({
        days = number
      })
    }))
    cors_rules = list(object({
      allowed_methods = list(string)
      allowed_origins = list(string)
      allowed_headers = list(string)
      expose_headers  = list(string)
      max_age_seconds = number
    }))
  }))
  default = {
    raw_data = {
      versioning = false
      lifecycle_rules = [
        {
          id      = "archive_old_data"
          enabled = true
          transitions = [
            {
              days          = 30
              storage_class = "STANDARD_IA"
            },
            {
              days          = 90
              storage_class = "GLACIER"
            }
          ]
          expiration = {
            days = 365
          }
        }
      ]
      cors_rules = []
    }
    processed_data = {
      versioning = true
      lifecycle_rules = [
        {
          id      = "cleanup_old_versions"
          enabled = true
          transitions = [
            {
              days          = 60
              storage_class = "STANDARD_IA"
            }
          ]
          expiration = {
            days = 180
          }
        }
      ]
      cors_rules = []
    }
    models = {
      versioning = true
      lifecycle_rules = []
      cors_rules = []
    }
  }
}

# ElastiCache Configuration
variable "elasticache_node_type" {
  description = "ElastiCache node instance type"
  type        = string
  default     = "cache.t3.micro"
}

variable "elasticache_num_cache_nodes" {
  description = "Number of cache nodes"
  type        = number
  default     = 1
}

variable "elasticache_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

# Monitoring & Logging
variable "enable_monitoring" {
  description = "Enable enhanced monitoring"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "enable_cloudtrail" {
  description = "Enable AWS CloudTrail"
  type        = bool
  default     = true
}

# Cost Optimization
variable "enable_spot_instances" {
  description = "Enable spot instances for cost savings"
  type        = bool
  default     = true
}

variable "spot_instance_pools" {
  description = "Number of spot instance pools"
  type        = number
  default     = 3
}

variable "on_demand_base_capacity" {
  description = "Base on-demand capacity"
  type        = number
  default     = 0
}

variable "on_demand_percentage_above_base" {
  description = "Percentage of on-demand instances above base"
  type        = number
  default     = 30
}

# Security
variable "enable_secrets_encryption" {
  description = "Enable encryption for secrets"
  type        = bool
  default     = true
}

variable "kms_key_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 30
}

variable "allowed_account_ids" {
  description = "List of allowed AWS account IDs"
  type        = list(string)
  default     = []
}

variable "assume_role_arn" {
  description = "ARN of role to assume for deployments"
  type        = string
  default     = ""
}

# Tagging
variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

variable "owner" {
  description = "Owner of the infrastructure"
  type        = string
  default     = "Platform Team"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "Engineering"
}

# Feature Flags
variable "enable_auto_scaling" {
  description = "Enable auto-scaling for services"
  type        = bool
  default     = true
}

variable "enable_disaster_recovery" {
  description = "Enable disaster recovery setup"
  type        = bool
  default     = false
}

variable "enable_cost_optimization" {
  description = "Enable aggressive cost optimization"
  type        = bool
  default     = true
}