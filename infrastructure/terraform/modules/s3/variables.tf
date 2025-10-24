# S3 Module Variables
# Configures S3 buckets for data storage with lifecycle management

variable "project_name" {
  description = "Project name for bucket naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "bucket_suffix" {
  description = "Suffix to add to bucket names for uniqueness"
  type        = string
  default     = ""
}

variable "force_destroy" {
  description = "Allow destruction of non-empty buckets"
  type        = bool
  default     = false
}

# Versioning configuration
variable "enable_versioning" {
  description = "Enable versioning for all buckets"
  type        = bool
  default     = true
}

variable "versioning_per_bucket" {
  description = "Override versioning per bucket"
  type = map(bool)
  default = {
    raw_data       = false
    processed_data = true
    models         = true
  }
}

# Encryption configuration
variable "enable_encryption" {
  description = "Enable server-side encryption"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
  default     = null
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm"
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "aws:kms"], var.sse_algorithm)
    error_message = "SSE algorithm must be AES256 or aws:kms"
  }
}

# Lifecycle rules
variable "raw_data_lifecycle_rules" {
  description = "Lifecycle rules for raw data bucket"
  type = list(object({
    id      = string
    enabled = bool
    
    transition = optional(list(object({
      days          = number
      storage_class = string
    })))
    
    expiration = optional(object({
      days = number
    }))
    
    noncurrent_version_transition = optional(list(object({
      days          = number
      storage_class = string
    })))
    
    noncurrent_version_expiration = optional(object({
      days = number
    }))
  }))
  default = [
    {
      id      = "archive_old_raw_data"
      enabled = true
      
      transition = [
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
}

variable "processed_data_lifecycle_rules" {
  description = "Lifecycle rules for processed data bucket"
  type = list(object({
    id      = string
    enabled = bool
    
    transition = optional(list(object({
      days          = number
      storage_class = string
    })))
    
    expiration = optional(object({
      days = number
    }))
    
    noncurrent_version_transition = optional(list(object({
      days          = number
      storage_class = string
    })))
    
    noncurrent_version_expiration = optional(object({
      days = number
    }))
  }))
  default = [
    {
      id      = "manage_processed_data"
      enabled = true
      
      transition = [
        {
          days          = 60
          storage_class = "STANDARD_IA"
        },
        {
          days          = 180
          storage_class = "GLACIER"
        }
      ]
      
      noncurrent_version_expiration = {
        days = 90
      }
    }
  ]
}

variable "models_lifecycle_rules" {
  description = "Lifecycle rules for models bucket"
  type = list(object({
    id      = string
    enabled = bool
    
    transition = optional(list(object({
      days          = number
      storage_class = string
    })))
    
    expiration = optional(object({
      days = number
    }))
    
    noncurrent_version_transition = optional(list(object({
      days          = number
      storage_class = string
    })))
    
    noncurrent_version_expiration = optional(object({
      days = number
    }))
  }))
  default = [
    {
      id      = "manage_old_model_versions"
      enabled = true
      
      noncurrent_version_transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        }
      ]
      
      noncurrent_version_expiration = {
        days = 180
      }
    }
  ]
}

# Bucket policies
variable "enable_public_access_block" {
  description = "Enable public access block on all buckets"
  type        = bool
  default     = true
}

variable "block_public_acls" {
  description = "Block public ACLs"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Block public bucket policies"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Ignore public ACLs"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Restrict public bucket policies"
  type        = bool
  default     = true
}

# CORS configuration
variable "enable_cors" {
  description = "Enable CORS for buckets"
  type        = bool
  default     = false
}

variable "cors_rules" {
  description = "CORS rules for buckets"
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = list(string)
    max_age_seconds = number
  }))
  default = []
}

# Logging configuration
variable "enable_logging" {
  description = "Enable access logging for buckets"
  type        = bool
  default     = false
}

variable "logging_target_bucket" {
  description = "Target bucket for access logs"
  type        = string
  default     = ""
}

variable "logging_target_prefix" {
  description = "Prefix for access logs"
  type        = string
  default     = "s3-logs/"
}

# Replication configuration
variable "enable_replication" {
  description = "Enable cross-region replication"
  type        = bool
  default     = false
}

variable "replication_configuration" {
  description = "Replication configuration"
  type = object({
    role = string
    rules = list(object({
      id       = string
      status   = string
      priority = number
      
      destination = object({
        bucket             = string
        storage_class      = string
        replica_kms_key_id = string
      })
      
      filter = optional(object({
        prefix = string
        tags   = map(string)
      }))
    }))
  })
  default = null
}

# Transfer acceleration
variable "enable_transfer_acceleration" {
  description = "Enable transfer acceleration for faster uploads"
  type        = bool
  default     = false
}

# Object lock configuration
variable "enable_object_lock" {
  description = "Enable object lock for compliance"
  type        = bool
  default     = false
}

variable "object_lock_configuration" {
  description = "Object lock configuration"
  type = object({
    mode = string
    days = number
  })
  default = null
}

# Intelligent tiering
variable "enable_intelligent_tiering" {
  description = "Enable intelligent tiering for automatic cost optimization"
  type        = bool
  default     = false
}

# Tags
variable "tags" {
  description = "Common tags for all buckets"
  type        = map(string)
  default     = {}
}

variable "bucket_tags" {
  description = "Specific tags per bucket"
  type = map(map(string))
  default = {
    raw_data = {
      DataType = "raw"
      Retention = "1year"
    }
    processed_data = {
      DataType = "processed"
      Retention = "6months"
    }
    models = {
      DataType = "models"
      Retention = "permanent"
    }
  }
}

# Notifications
variable "enable_notifications" {
  description = "Enable bucket notifications"
  type        = bool
  default     = false
}

variable "notification_configuration" {
  description = "Bucket notification configuration"
  type = object({
    lambda_functions = optional(list(object({
      id                  = string
      lambda_function_arn = string
      events              = list(string)
      filter_prefix       = string
      filter_suffix       = string
    })))
    
    sqs_queues = optional(list(object({
      id            = string
      queue_arn     = string
      events        = list(string)
      filter_prefix = string
      filter_suffix = string
    })))
    
    sns_topics = optional(list(object({
      id            = string
      topic_arn     = string
      events        = list(string)
      filter_prefix = string
      filter_suffix = string
    })))
  })
  default = null
}

# Metrics configuration
variable "enable_metrics" {
  description = "Enable bucket metrics"
  type        = bool
  default     = true
}

# Inventory configuration
variable "enable_inventory" {
  description = "Enable S3 inventory for bucket analysis"
  type        = bool
  default     = false
}

variable "inventory_configuration" {
  description = "S3 inventory configuration"
  type = object({
    destination_bucket = string
    frequency         = string
    format           = string
    included_object_versions = string
    optional_fields  = list(string)
  })
  default = null
}