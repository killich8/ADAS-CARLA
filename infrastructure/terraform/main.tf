# Main Terraform configuration - VPC
# This file orchestrates all modules and creates the infrastructure

module "vpc" {
  source = "./modules/vpc"
  
  name        = var.project_name
  environment = var.environment
  cidr        = var.vpc_cidr
  azs         = var.azs
  
  # Calculate subnets from locals (defined in locals.tf)
  public_subnets   = local.public_subnet_cidrs
  private_subnets  = local.private_subnet_cidrs
  database_subnets = local.database_subnet_cidrs
  
  # NAT Gateway configuration
  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = !var.single_nat_gateway
  
  # DNS configuration
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  # VPN configuration
  enable_vpn_gateway = var.enable_vpn_gateway
  
  # Flow logs configuration
  enable_flow_logs         = var.enable_flow_logs
  flow_logs_retention_days = var.log_retention_days
  
  # VPC Endpoints for cost optimization
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true
  enable_ec2_endpoint      = local.is_production
  enable_ecr_endpoints     = local.is_production
  
  # Network ACLs
  public_dedicated_network_acl   = local.is_production
  private_dedicated_network_acl  = local.is_production
  database_dedicated_network_acl = local.is_production
  
  # Subnet tags for Kubernetes
  public_subnet_tags = merge(
    {
      "kubernetes.io/role/elb"                        = "1"
      "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
    },
    local.cost_tags
  )
  
  private_subnet_tags = merge(
    {
      "kubernetes.io/role/internal-elb"               = "1"
      "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
      "karpenter.sh/discovery"                        = local.eks_cluster_name
    },
    local.cost_tags
  )
  
  database_subnet_tags = merge(
    {
      "db-subnet" = "true"
      "tier"      = "database"
    },
    local.cost_tags
  )
  
  # Common tags
  tags = merge(
    local.common_tags,
    local.cost_tags,
    {
      Component = "networking"
    }
  )
}


# Additional Security Groups
# Security group for ALB
resource "aws_security_group" "alb" {
  name_prefix = "${local.name_prefix}-alb-"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc.vpc_id
  
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-alb-sg"
      Type = "alb"
    }
  )
  
  lifecycle {
    create_before_destroy = true
  }
}

# Security group for RDS
resource "aws_security_group" "rds" {
  name_prefix = "${local.name_prefix}-rds-"
  description = "Security group for RDS database"
  vpc_id      = module.vpc.vpc_id
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-rds-sg"
      Type = "database"
    }
  )
  
  lifecycle {
    create_before_destroy = true
  }
}

# Allow PostgreSQL from private subnets
resource "aws_security_group_rule" "rds_from_private" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = aws_security_group.rds.id
  cidr_blocks       = module.vpc.private_subnets_cidr_blocks
  description       = "PostgreSQL from private subnets"
}

# Security group for Redis/ElastiCache
resource "aws_security_group" "redis" {
  name_prefix = "${local.name_prefix}-redis-"
  description = "Security group for ElastiCache Redis"
  vpc_id      = module.vpc.vpc_id
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-redis-sg"
      Type = "cache"
    }
  )
  
  lifecycle {
    create_before_destroy = true
  }
}

# Allow Redis from private subnets
resource "aws_security_group_rule" "redis_from_private" {
  type              = "ingress"
  from_port         = 6379
  to_port           = 6379
  protocol          = "tcp"
  security_group_id = aws_security_group.redis.id
  cidr_blocks       = module.vpc.private_subnets_cidr_blocks
  description       = "Redis from private subnets"
}

# Security group for CARLA instances
resource "aws_security_group" "carla" {
  name_prefix = "${local.name_prefix}-carla-"
  description = "Security group for CARLA simulator instances"
  vpc_id      = module.vpc.vpc_id
  
  # CARLA server ports
  ingress {
    description = "CARLA RPC port"
    from_port   = 2000
    to_port     = 2000
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnets_cidr_blocks
  }
  
  ingress {
    description = "CARLA streaming port"
    from_port   = 2001
    to_port     = 2001
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnets_cidr_blocks
  }
  
  ingress {
    description = "CARLA secondary port"
    from_port   = 2002
    to_port     = 2002
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnets_cidr_blocks
  }
  
  # Traffic Manager ports
  ingress {
    description = "Traffic Manager"
    from_port   = 8000
    to_port     = 8002
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnets_cidr_blocks
  }
  
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(
    local.common_tags,
    {
      Name      = "${local.name_prefix}-carla-sg"
      Type      = "simulation"
      Component = "carla"
    }
  )
  
  lifecycle {
    create_before_destroy = true
  }
}


