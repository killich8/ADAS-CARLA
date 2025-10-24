# S3 Buckets Configuration
# Uses the S3 module to create storage buckets for the data pipeline


# S3 Module
module "s3" {
  source = "./modules/s3"
  
  project_name  = var.project_name
  environment   = var.environment
  bucket_suffix = ""  
  
  # Allow destroy in dev, prevent in prod
  force_destroy = !local.is_production
  
  # Versioning configuration
  versioning_per_bucket = {
    raw_data       = local.is_production  
    processed_data = true                 
    models         = true                  
  }
  
  # Encryption
  enable_encryption = var.enable_secrets_encryption
  sse_algorithm    = var.enable_secrets_encryption ? "aws:kms" : "AES256"
  kms_key_arn      = var.enable_secrets_encryption ? aws_kms_key.s3[0].arn : null
  
  # Lifecycle rules based on environment
  raw_data_lifecycle_rules = local.is_production ? [
    {
      id      = "archive_raw_data"
      enabled = true
      
      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        },
        {
          days          = 365
          storage_class = "DEEP_ARCHIVE"
        }
      ]
      
      expiration = {
        days = 730  # 2 years
      }
    }
  ] : [
    {
      id      = "cleanup_dev_data"
      enabled = true
      
      expiration = {
        days = 7  # Quick cleanup in dev
      }
    }
  ]
  
  processed_data_lifecycle_rules = local.is_production ? [
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
  ] : [
    {
      id      = "cleanup_dev_processed"
      enabled = true
      
      expiration = {
        days = 30
      }
      
      noncurrent_version_expiration = {
        days = 7
      }
    }
  ]
  
  models_lifecycle_rules = [
    {
      id      = "archive_old_models"
      enabled = true
      
      noncurrent_version_transition = local.is_production ? [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ] : []
      
      noncurrent_version_expiration = local.is_production ? null : {
        days = 30  
      }
    }
  ]
  
  # Advanced features for production
  enable_logging               = local.is_production
  enable_metrics              = true
  enable_transfer_acceleration = local.is_production
  enable_intelligent_tiering   = local.is_production && var.enable_cost_optimization
  
  # Cross-region replication for DR (production only)
  enable_replication = local.is_production && var.enable_disaster_recovery
  
  # Tags
  tags = merge(
    local.common_tags,
    local.cost_tags,
    {
      Component = "storage"
      DataTier  = "s3"
    }
  )
  
  bucket_tags = {
    raw_data = {
      DataType    = "raw"
      Retention   = local.is_production ? "2years" : "7days"
      Compliance  = "none"
    }
    processed_data = {
      DataType    = "processed"
      Retention   = local.is_production ? "1year" : "30days"
      Compliance  = "none"
    }
    models = {
      DataType    = "models"
      Retention   = "permanent"
      Compliance  = "required"
      Critical    = "true"
    }
  }
}


# KMS Key for S3 Encryption (Optional)
resource "aws_kms_key" "s3" {
  count = var.enable_secrets_encryption ? 1 : 0
  
  description             = "KMS key for S3 bucket encryption in ${var.environment}"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = true
  
  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-s3-kms"
      Purpose = "s3-encryption"
    }
  )
}

resource "aws_kms_alias" "s3" {
  count = var.enable_secrets_encryption ? 1 : 0
  
  name          = "alias/${var.project_name}-${var.environment}-s3"
  target_key_id = aws_kms_key.s3[0].key_id
}



# Policy for S3 VPC endpoint to restrict access
resource "aws_vpc_endpoint_policy" "s3" {
  count = module.vpc.vpc_endpoint_s3_id != "" ? 1 : 0
  
  vpc_endpoint_id = module.vpc.vpc_endpoint_s3_id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          module.s3.raw_data_bucket_arn,
          "${module.s3.raw_data_bucket_arn}/*",
          module.s3.processed_data_bucket_arn,
          "${module.s3.processed_data_bucket_arn}/*",
          module.s3.models_bucket_arn,
          "${module.s3.models_bucket_arn}/*"
        ]
        Condition = {
          StringEquals = {
            "aws:PrincipalAccount" = local.account_id
          }
        }
      }
    ]
  })
}



# S3 Bucket Notifications (Optional)
# SQS Queue for S3 notifications (example)
resource "aws_sqs_queue" "s3_events" {
  count = local.is_production ? 1 : 0
  
  name                       = "${local.name_prefix}-s3-events"
  visibility_timeout_seconds = 300
  message_retention_seconds  = 86400  # 1 day
  
  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-s3-events"
      Purpose = "s3-notifications"
    }
  )
}

# Policy allowing S3 to send messages to SQS
resource "aws_sqs_queue_policy" "s3_events" {
  count = local.is_production ? 1 : 0
  
  queue_url = aws_sqs_queue.s3_events[0].url
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.s3_events[0].arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = [
              module.s3.raw_data_bucket_arn,
              module.s3.processed_data_bucket_arn,
              module.s3.models_bucket_arn
            ]
          }
        }
      }
    ]
  })
}


# CloudWatch Alarms for S3
# Alarm for bucket size (cost monitoring)
resource "aws_cloudwatch_metric_alarm" "s3_bucket_size" {
  for_each = local.is_production ? {
    raw       = module.s3.raw_data_bucket_id
    processed = module.s3.processed_data_bucket_id
    models    = module.s3.models_bucket_id
  } : {}
  
  alarm_name          = "${each.value}-size-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name        = "BucketSizeBytes"
  namespace          = "AWS/S3"
  period             = "86400"  # Daily
  statistic          = "Maximum"
  threshold          = each.key == "models" ? 107374182400 : 1099511627776  # 100GB for models, 1TB for others
  alarm_description  = "Alert when ${each.key} bucket exceeds size threshold"
  
  dimensions = {
    BucketName = each.value
    StorageType = "StandardStorage"
  }
  
  tags = local.common_tags
}


# IAM Roles for S3 Access
# Role for CARLA instances to write raw data
resource "aws_iam_role" "carla_s3_writer" {
  name = "${local.name_prefix}-carla-s3-writer"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  
  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-carla-s3-writer"
      Purpose = "s3-write-access"
    }
  )
}

# Attach write policy to CARLA role
resource "aws_iam_role_policy_attachment" "carla_s3_writer" {
  role       = aws_iam_role.carla_s3_writer.name
  policy_arn = module.s3.read_write_policy_arn
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "carla_s3_writer" {
  name = "${local.name_prefix}-carla-s3-writer"
  role = aws_iam_role.carla_s3_writer.name
}