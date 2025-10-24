# Example usage of S3 module


provider "aws" {
  region = "eu-west-1"
}

# Random suffix for unique bucket names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Use the S3 module
module "s3_test" {
  source = "../../"
  
  project_name  = "test-s3"
  environment   = "test"
  bucket_suffix = "-${random_string.suffix.result}"
  
  # Allow destruction for testing
  force_destroy = true
  
  # Simple versioning setup
  versioning_per_bucket = {
    raw_data       = false
    processed_data = true
    models         = true
  }
  
  # Basic lifecycle rules
  raw_data_lifecycle_rules = [
    {
      id      = "cleanup_test"
      enabled = true
      
      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        }
      ]
      
      expiration = {
        days = 90
      }
    }
  ]
  
  processed_data_lifecycle_rules = [
    {
      id      = "archive_processed"
      enabled = true
      
      transition = [
        {
          days          = 60
          storage_class = "STANDARD_IA"
        }
      ]
      
      noncurrent_version_expiration = {
        days = 30
      }
    }
  ]
  
  models_lifecycle_rules = []
  
  # Disable advanced features for testing
  enable_logging               = false
  enable_metrics              = false
  enable_transfer_acceleration = false
  enable_intelligent_tiering   = false
  enable_replication          = false
  
  # Basic encryption
  enable_encryption = true
  sse_algorithm    = "AES256"
  
  # Tags
  tags = {
    Purpose     = "module-testing"
    Environment = "test"
    Temporary   = "true"
  }
  
  bucket_tags = {
    raw_data = {
      DataType = "test-raw"
    }
    processed_data = {
      DataType = "test-processed"
    }
    models = {
      DataType = "test-models"
    }
  }
}

# Outputs for testing
output "raw_data_bucket" {
  value = module.s3_test.raw_data_bucket_id
}

output "processed_data_bucket" {
  value = module.s3_test.processed_data_bucket_id
}

output "models_bucket" {
  value = module.s3_test.models_bucket_id
}

output "all_bucket_arns" {
  value = module.s3_test.all_bucket_arns
}

output "versioning_status" {
  value = module.s3_test.versioning_status
}

output "lifecycle_rules" {
  value = module.s3_test.lifecycle_rules_configured
}