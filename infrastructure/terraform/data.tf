# Data sources for existing AWS resources and information
# Used to fetch current state and available resources

# Current AWS account information
data "aws_caller_identity" "current" {}

# Current AWS region
data "aws_region" "current" {}

# Available AZs in the region
data "aws_availability_zones" "available" {
  state = "available"
  
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Latest Amazon Linux 2 AMI for EKS
data "aws_ami" "eks_node" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.eks_cluster_version}-*"]
  }
  
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Latest GPU-optimized AMI for EKS
data "aws_ami" "eks_gpu_node" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amazon-eks-gpu-node-${var.eks_cluster_version}-*"]
  }
  
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Ubuntu AMI for custom instances
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Get the certificate for RDS
data "aws_rds_certificate" "latest" {
  latest_valid_till = true
}

# EKS cluster auth
data "aws_eks_cluster_auth" "cluster" {
  count = var.environment != "" ? 1 : 0
  name  = local.eks_cluster_name
  
  depends_on = [module.eks]
}

# KMS key for encryption (if it exists)
data "aws_kms_key" "eks" {
  key_id = "alias/eks-${var.environment}"
}

data "aws_kms_key" "rds" {
  key_id = "alias/rds-${var.environment}"
}

data "aws_kms_key" "s3" {
  key_id = "alias/s3-${var.environment}"
}

# Get the default VPC (for reference)
data "aws_vpc" "default" {
  default = true
}

# IAM policy documents
data "aws_iam_policy_document" "eks_assume_role" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "eks_node_assume_role" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    
    actions = ["sts:AssumeRole"]
  }
}

# Get Route53 hosted zone (if exists)
data "aws_route53_zone" "main" {
  count = var.environment != "" ? 1 : 0
  name  = "${var.project_name}.com"
  
  # Don't fail if zone doesn't exist
  lifecycle {
    ignore_errors = true
  }
}

# SSM Parameters for secrets (if they exist)
data "aws_ssm_parameter" "db_password" {
  count = var.environment != "" ? 1 : 0
  name  = "/${var.project_name}/${var.environment}/db/password"
  
  # Don't fail if parameter doesn't exist
  lifecycle {
    ignore_errors = true
  }
}

# Get the current AWS partition (aws, aws-cn, aws-us-gov)
data "aws_partition" "current" {}

# Instance types available in the region
data "aws_ec2_instance_types" "available" {
  filter {
    name   = "processor-info.supported-architecture"
    values = ["x86_64"]
  }
  
  filter {
    name   = "instance-type"
    values = ["t3.*", "c5.*", "g4dn.*"]
  }
}