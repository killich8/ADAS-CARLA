# S3 Module - Main Configuration


locals {
  # Account ID
  account_id = data.aws_caller_identity.current.account_id
  
  # Bucket names
  bucket_names = {
    raw_data       = "${var.project_name}-${var.environment}-raw-${local.account_id}${var.bucket_suffix}"
    processed_data = "${var.project_name}-${var.environment}-processed-${local.account_id}${var.bucket_suffix}"
    models         = "${var.project_name}-${var.environment}-models-${local.account_id}${var.bucket_suffix}"
    logs           = var.enable_logging ? "${var.project_name}-${var.environment}-logs-${local.account_id}${var.bucket_suffix}" : ""
  }
  
  # Common tags
  common_tags = merge(
    var.tags,
    {
      Module      = "s3"
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  )
}


# Raw Data Bucket
resource "aws_s3_bucket" "raw_data" {
  bucket        = local.bucket_names.raw_data
  force_destroy = var.force_destroy
  
  tags = merge(
    local.common_tags,
    var.bucket_tags["raw_data"],
    {
      Name       = local.bucket_names.raw_data
      BucketType = "raw-data"
    }
  )
}

# Versioning for raw data
resource "aws_s3_bucket_versioning" "raw_data" {
  bucket = aws_s3_bucket.raw_data.id
  
  versioning_configuration {
    status = var.versioning_per_bucket["raw_data"] ? "Enabled" : "Suspended"
  }
}

# Encryption for raw data
resource "aws_s3_bucket_server_side_encryption_configuration" "raw_data" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.raw_data.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = var.sse_algorithm == "aws:kms" ? var.kms_key_arn : null
    }
    bucket_key_enabled = var.sse_algorithm == "aws:kms" ? true : false
  }
}

# Lifecycle rules for raw data
resource "aws_s3_bucket_lifecycle_configuration" "raw_data" {
  count  = length(var.raw_data_lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.raw_data.id
  
  dynamic "rule" {
    for_each = var.raw_data_lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"
      
      # Transitions to different storage classes
      dynamic "transition" {
        for_each = rule.value.transition != null ? rule.value.transition : []
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }
      
      # Expiration
      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [rule.value.expiration] : []
        content {
          days = expiration.value.days
        }
      }
      
      # Noncurrent version transitions
      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transition != null ? rule.value.noncurrent_version_transition : []
        content {
          noncurrent_days = noncurrent_version_transition.value.days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }
      
      # Noncurrent version expiration
      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration != null ? [rule.value.noncurrent_version_expiration] : []
        content {
          noncurrent_days = noncurrent_version_expiration.value.days
        }
      }
    }
  }
  
  depends_on = [aws_s3_bucket_versioning.raw_data]
}


# Processed Data Bucket
resource "aws_s3_bucket" "processed_data" {
  bucket        = local.bucket_names.processed_data
  force_destroy = var.force_destroy
  
  tags = merge(
    local.common_tags,
    var.bucket_tags["processed_data"],
    {
      Name       = local.bucket_names.processed_data
      BucketType = "processed-data"
    }
  )
}

# Versioning for processed data
resource "aws_s3_bucket_versioning" "processed_data" {
  bucket = aws_s3_bucket.processed_data.id
  
  versioning_configuration {
    status = var.versioning_per_bucket["processed_data"] ? "Enabled" : "Suspended"
  }
}

# Encryption for processed data
resource "aws_s3_bucket_server_side_encryption_configuration" "processed_data" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.processed_data.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = var.sse_algorithm == "aws:kms" ? var.kms_key_arn : null
    }
    bucket_key_enabled = var.sse_algorithm == "aws:kms" ? true : false
  }
}

# Lifecycle rules for processed data
resource "aws_s3_bucket_lifecycle_configuration" "processed_data" {
  count  = length(var.processed_data_lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.processed_data.id
  
  dynamic "rule" {
    for_each = var.processed_data_lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"
      
      dynamic "transition" {
        for_each = rule.value.transition != null ? rule.value.transition : []
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }
      
      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [rule.value.expiration] : []
        content {
          days = expiration.value.days
        }
      }
      
      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transition != null ? rule.value.noncurrent_version_transition : []
        content {
          noncurrent_days = noncurrent_version_transition.value.days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }
      
      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration != null ? [rule.value.noncurrent_version_expiration] : []
        content {
          noncurrent_days = noncurrent_version_expiration.value.days
        }
      }
    }
  }
  
  depends_on = [aws_s3_bucket_versioning.processed_data]
}


# Models Bucket
resource "aws_s3_bucket" "models" {
  bucket        = local.bucket_names.models
  force_destroy = var.force_destroy
  
  tags = merge(
    local.common_tags,
    var.bucket_tags["models"],
    {
      Name       = local.bucket_names.models
      BucketType = "models"
      Critical   = "true"  
    }
  )
}

# Versioning for models (always enabled for models)
resource "aws_s3_bucket_versioning" "models" {
  bucket = aws_s3_bucket.models.id
  
  versioning_configuration {
    status = "Enabled"  # Always version models
  }
}

# Encryption for models
resource "aws_s3_bucket_server_side_encryption_configuration" "models" {
  bucket = aws_s3_bucket.models.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm == "aws:kms" ? "aws:kms" : "AES256"
      kms_master_key_id = var.sse_algorithm == "aws:kms" ? var.kms_key_arn : null
    }
    bucket_key_enabled = var.sse_algorithm == "aws:kms" ? true : false
  }
}

# Lifecycle rules for models
resource "aws_s3_bucket_lifecycle_configuration" "models" {
  count  = length(var.models_lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.models.id
  
  dynamic "rule" {
    for_each = var.models_lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"
      
      dynamic "transition" {
        for_each = rule.value.transition != null ? rule.value.transition : []
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }
      
      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transition != null ? rule.value.noncurrent_version_transition : []
        content {
          noncurrent_days = noncurrent_version_transition.value.days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }
      
      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration != null ? [rule.value.noncurrent_version_expiration] : []
        content {
          noncurrent_days = noncurrent_version_expiration.value.days
        }
      }
    }
  }
  
  depends_on = [aws_s3_bucket_versioning.models]
}


# Logs Bucket
resource "aws_s3_bucket" "logs" {
  count = var.enable_logging ? 1 : 0
  
  bucket        = local.bucket_names.logs
  force_destroy = var.force_destroy
  
  tags = merge(
    local.common_tags,
    {
      Name       = local.bucket_names.logs
      BucketType = "logs"
    }
  )
}

# ACL for logs bucket
resource "aws_s3_bucket_acl" "logs" {
  count = var.enable_logging ? 1 : 0
  
  bucket = aws_s3_bucket.logs[0].id
  acl    = "log-delivery-write"
}

# Lifecycle for logs
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id
  
  rule {
    id     = "delete_old_logs"
    status = "Enabled"
    
    expiration {
      days = 30  # Keep logs for 30 days
    }
  }
}


# Public Access Block (Applied to all buckets)
resource "aws_s3_bucket_public_access_block" "buckets" {
  for_each = {
    raw_data       = aws_s3_bucket.raw_data.id
    processed_data = aws_s3_bucket.processed_data.id
    models         = aws_s3_bucket.models.id
  }
  
  bucket = each.value
  
  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}


# CORS Configuration (Optional)
resource "aws_s3_bucket_cors_configuration" "buckets" {
  for_each = var.enable_cors ? {
    raw_data       = aws_s3_bucket.raw_data.id
    processed_data = aws_s3_bucket.processed_data.id
    models         = aws_s3_bucket.models.id
  } : {}
  
  bucket = each.value
  
  dynamic "cors_rule" {
    for_each = var.cors_rules
    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}


# Logging Configuration (Optional)
resource "aws_s3_bucket_logging" "buckets" {
  for_each = var.enable_logging ? {
    raw_data       = aws_s3_bucket.raw_data.id
    processed_data = aws_s3_bucket.processed_data.id
    models         = aws_s3_bucket.models.id
  } : {}
  
  bucket = each.value
  
  target_bucket = var.enable_logging ? aws_s3_bucket.logs[0].id : var.logging_target_bucket
  target_prefix = "${var.logging_target_prefix}${each.key}/"
}


# Transfer Acceleration (Optional)
resource "aws_s3_bucket_accelerate_configuration" "buckets" {
  for_each = var.enable_transfer_acceleration ? {
    raw_data       = aws_s3_bucket.raw_data.id
    processed_data = aws_s3_bucket.processed_data.id
    models         = aws_s3_bucket.models.id
  } : {}
  
  bucket = each.value
  status = "Enabled"
}


# Intelligent Tiering (Optional)
resource "aws_s3_bucket_intelligent_tiering_configuration" "buckets" {
  for_each = var.enable_intelligent_tiering ? {
    raw_data       = aws_s3_bucket.raw_data.id
    processed_data = aws_s3_bucket.processed_data.id
  } : {}
  
  bucket = each.value
  name   = "${each.key}_intelligent_tiering"
  
  # Archive configurations for automatic tiering
  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }
  
  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
}


# Bucket Metrics (Optional)
resource "aws_s3_bucket_metric" "buckets" {
  for_each = var.enable_metrics ? {
    raw_data       = aws_s3_bucket.raw_data.id
    processed_data = aws_s3_bucket.processed_data.id
    models         = aws_s3_bucket.models.id
  } : {}
  
  bucket = each.value
  name   = "${each.key}_entire_bucket"
  
}


# Bucket Notifications (Optional)
resource "aws_s3_bucket_notification" "buckets" {
  for_each = var.enable_notifications && var.notification_configuration != null ? {
    raw_data       = aws_s3_bucket.raw_data.id
    processed_data = aws_s3_bucket.processed_data.id
    models         = aws_s3_bucket.models.id
  } : {}
  
  bucket = each.value
  
  # Lambda function notifications
  dynamic "lambda_function" {
    for_each = var.notification_configuration.lambda_functions != null ? var.notification_configuration.lambda_functions : []
    content {
      id                  = lambda_function.value.id
      lambda_function_arn = lambda_function.value.lambda_function_arn
      events              = lambda_function.value.events
      filter_prefix       = lambda_function.value.filter_prefix
      filter_suffix       = lambda_function.value.filter_suffix
    }
  }
  
  # SQS queue notifications
  dynamic "queue" {
    for_each = var.notification_configuration.sqs_queues != null ? var.notification_configuration.sqs_queues : []
    content {
      id            = queue.value.id
      queue_arn     = queue.value.queue_arn
      events        = queue.value.events
      filter_prefix = queue.value.filter_prefix
      filter_suffix = queue.value.filter_suffix
    }
  }
  
  # SNS topic notifications
  dynamic "topic" {
    for_each = var.notification_configuration.sns_topics != null ? var.notification_configuration.sns_topics : []
    content {
      id            = topic.value.id
      topic_arn     = topic.value.topic_arn
      events        = topic.value.events
      filter_prefix = topic.value.filter_prefix
      filter_suffix = topic.value.filter_suffix
    }
  }
}