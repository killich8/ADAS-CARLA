# Remote backend configuration for Terraform state
# Stores state in S3 and uses DynamoDB for state locking

terraform {
  backend "s3" {
    # Backend settings are typically loaded from an external config file
    # Example: terraform init -backend-config="backend-dev.hcl"
    
    bucket         = "adas-carla-terraform-state"
    key            = "infrastructure/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    kms_key_id     = "alias/terraform-state"
    
    # DynamoDB table for state locking
    dynamodb_table = "adas-carla-terraform-locks"
    
    # Workspace prefix used to organize workspace-specific state files (dev, prod, etc.)
    workspace_key_prefix = "environments"
    
    # Keep historical versions of the state file for recovery
    versioning = true
    
    # Server-side encryption
    server_side_encryption_configuration {
      rule {
        apply_server_side_encryption_by_default {
          sse_algorithm = "aws:kms"
        }
      }
    }
  }
}