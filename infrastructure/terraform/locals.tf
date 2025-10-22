# Local values and computed variables
# Central place for naming, tags, and derived settings

locals {
  # name prefix
  name_prefix = "${var.project_name}-${var.environment}"
  
  # EKS cluster name reused across modules/resources
  eks_cluster_name = "${local.name_prefix}-eks"
  
  # Filled after the EKS module is created
  eks_cluster_endpoint = try(module.eks.cluster_endpoint, "")
  eks_cluster_ca       = try(module.eks.cluster_certificate_authority_data, "")
  
  # Account ID
  account_id = data.aws_caller_identity.current.account_id
  
  # VPC Configuration
  vpc_name = "${local.name_prefix}-vpc"
  
  # subnet CIDR blocks
  public_subnet_cidrs  = [for i in range(length(var.azs)) : cidrsubnet(var.vpc_cidr, 4, i)]
  private_subnet_cidrs = [for i in range(length(var.azs)) : cidrsubnet(var.vpc_cidr, 4, i + length(var.azs))]
  database_subnet_cidrs = [for i in range(length(var.azs)) : cidrsubnet(var.vpc_cidr, 8, i + 48)]
  
  # S3 bucket names (global uniqueness via account id)
  s3_bucket_prefix = "${local.name_prefix}-${local.account_id}"
  
  # RDS naming helpers
  db_name     = replace(var.project_name, "-", "_")
  db_username = "adas_admin"
  
  # Common tags applied across resources
  common_tags = merge(
    var.tags,
    {
      Project             = var.project_name
      Environment         = var.environment
      ManagedBy          = "Terraform"
      Owner              = var.owner
      CostCenter         = var.cost_center
      CreatedAt          = timestamp()
      TerraformWorkspace = terraform.workspace
      GitRepo            = "https://github.com/killich8/ADAS-CARLA.git"
    }
  )
  
  # EKS specific tags
  eks_tags = merge(
    local.common_tags,
    {
      "kubernetes.io/cluster/${local.eks_cluster_name}" = "owned"
      Platform = "Kubernetes"
    }
  )
  
  # Cost allocation tags
  cost_tags = {
    BusinessUnit = var.cost_center
    Environment  = var.environment
    Application  = var.project_name
  }
  
  # Environment flags
  is_production = var.environment == "prod"
  is_staging    = var.environment == "staging"
  is_development = var.environment == "dev"
  
  # Default node group bounds per environment
  node_group_defaults = {
    dev = {
      system_min  = 1
      system_max  = 2
      compute_min = 1
      compute_max = 3
      gpu_min     = 0
      gpu_max     = 2
    }
    staging = {
      system_min  = 2
      system_max  = 3
      compute_min = 2
      compute_max = 5
      gpu_min     = 1
      gpu_max     = 5
    }
    prod = {
      system_min  = 3
      system_max  = 5
      compute_min = 3
      compute_max = 20
      gpu_min     = 2
      gpu_max     = 30
    }
  }
  
  # Pick the bounds for the current environment
  node_config = local.node_group_defaults[var.environment]
  
  # Monitoring configuration
  monitoring_config = {
    metrics_namespace    = "ADAS-CARLA/${var.environment}"
    log_group_prefix    = "/aws/adas-carla/${var.environment}"
    alarm_email         = var.environment == "prod" ? "youness.killich@gmail.com" : "youness.killich@gmail.com"
    enable_detailed     = local.is_production
  }
  
  # Backup policy per environment
  backup_config = {
    dev = {
      retention_days = 3
      backup_window  = "03:00-04:00"
    }
    staging = {
      retention_days = 7
      backup_window  = "02:00-03:00"
    }
    prod = {
      retention_days = 30
      backup_window  = "01:00-02:00"
    }
  }
  
  # Security groups naming
  sg_names = {
    alb        = "${local.name_prefix}-alb-sg"
    eks_cluster = "${local.name_prefix}-eks-cluster-sg"
    eks_nodes  = "${local.name_prefix}-eks-nodes-sg"
    rds        = "${local.name_prefix}-rds-sg"
    redis      = "${local.name_prefix}-redis-sg"
    vpn        = "${local.name_prefix}-vpn-sg"
  }
  
  # CARLA specific configuration
  carla_config = {
    port_range_start = 2000
    port_range_end   = 2100
    gpu_node_selector = {
      "nvidia.com/gpu" = "true"
      "role"          = "gpu"
    }
    tolerations = [
      {
        key      = "nvidia.com/gpu"
        operator = "Exists"
        effect   = "NoSchedule"
      }
    ]
  }
  
  # Cost optimization settings
  spot_config = var.enable_spot_instances ? {
    enabled                          = true
    on_demand_base_capacity         = var.on_demand_base_capacity
    on_demand_percentage_above_base = var.on_demand_percentage_above_base
    spot_instance_pools             = var.spot_instance_pools
    spot_max_price                  = ""  # Use on-demand price as max
  } : {
    enabled                          = false
    on_demand_base_capacity         = 100
    on_demand_percentage_above_base = 100
    spot_instance_pools             = 0
    spot_max_price                  = ""
  }
}