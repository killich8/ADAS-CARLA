# Define Terraform and provider version constraints

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# AWS Provider configuration
provider "aws" {
  region = var.aws_region
  
  # tags
  default_tags {
    tags = local.common_tags
  }
  

  dynamic "assume_role" {
    for_each = var.assume_role_arn != "" ? [1] : []
    content {
      role_arn = var.assume_role_arn
    }
  }
}

# Kubernetes provider – initialized after EKS cluster creation
provider "kubernetes" {
  host                   = local.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(local.eks_cluster_ca)
  
  # Use AWS CLI for authentication (EKS get-token)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      local.eks_cluster_name,
      "--region",
      var.aws_region
    ]
  }
}

# Helm provider – used to deploy Helm charts on the EKS cluster
provider "helm" {
  kubernetes {
    host                   = local.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(local.eks_cluster_ca)
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        local.eks_cluster_name,
        "--region",
        var.aws_region
      ]
    }
  }
}