# IAM Policies and Roles for S3 Module
# Manages permissions for bucket access and replication


# Replication Role
resource "aws_iam_role" "replication" {
  count = var.enable_replication ? 1 : 0
  
  name = "${var.project_name}-${var.environment}-s3-replication-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  
  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-s3-replication-role"
      Type = "replication"
    }
  )
}

# Replication policy
resource "aws_iam_role_policy" "replication" {
  count = var.enable_replication ? 1 : 0
  
  name = "${var.project_name}-${var.environment}-s3-replication-policy"
  role = aws_iam_role.replication[0].id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.raw_data.arn,
          aws_s3_bucket.processed_data.arn,
          aws_s3_bucket.models.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = [
          "${aws_s3_bucket.raw_data.arn}/*",
          "${aws_s3_bucket.processed_data.arn}/*",
          "${aws_s3_bucket.models.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = var.replication_configuration != null ? [
          for rule in var.replication_configuration.rules : "${rule.destination.bucket}/*"
        ] : []
      }
    ]
  })
}



# Read-Only Policy Document
data "aws_iam_policy_document" "read_only" {
  statement {
    sid    = "ListBuckets"
    effect = "Allow"
    
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketVersioning",
      "s3:GetBucketTagging",
      "s3:GetLifecycleConfiguration"
    ]
    
    resources = [
      aws_s3_bucket.raw_data.arn,
      aws_s3_bucket.processed_data.arn,
      aws_s3_bucket.models.arn
    ]
  }
  
  statement {
    sid    = "ReadObjects"
    effect = "Allow"
    
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetObjectTagging",
      "s3:GetObjectVersionTagging"
    ]
    
    resources = [
      "${aws_s3_bucket.raw_data.arn}/*",
      "${aws_s3_bucket.processed_data.arn}/*",
      "${aws_s3_bucket.models.arn}/*"
    ]
  }
}

# Create the read-only policy
resource "aws_iam_policy" "read_only" {
  name        = "${var.project_name}-${var.environment}-s3-read-only"
  description = "Read-only access to ${var.project_name} S3 buckets"
  policy      = data.aws_iam_policy_document.read_only.json
  
  tags = local.common_tags
}



# Read-Write Policy Document
data "aws_iam_policy_document" "read_write" {
  statement {
    sid    = "ListBuckets"
    effect = "Allow"
    
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketVersioning",
      "s3:GetBucketTagging",
      "s3:GetLifecycleConfiguration"
    ]
    
    resources = [
      aws_s3_bucket.raw_data.arn,
      aws_s3_bucket.processed_data.arn,
      aws_s3_bucket.models.arn
    ]
  }
  
  statement {
    sid    = "ReadWriteObjects"
    effect = "Allow"
    
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetObjectTagging",
      "s3:GetObjectVersionTagging",
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:RestoreObject"
    ]
    
    resources = [
      "${aws_s3_bucket.raw_data.arn}/*",
      "${aws_s3_bucket.processed_data.arn}/*",
      "${aws_s3_bucket.models.arn}/*"
    ]
  }
  
  # Add KMS permissions if encryption is enabled
  dynamic "statement" {
    for_each = var.enable_encryption && var.sse_algorithm == "aws:kms" ? [1] : []
    
    content {
      sid    = "KMSPermissions"
      effect = "Allow"
      
      actions = [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey",
        "kms:DescribeKey"
      ]
      
      resources = [var.kms_key_arn]
    }
  }
}

# Create the read-write policy
resource "aws_iam_policy" "read_write" {
  name        = "${var.project_name}-${var.environment}-s3-read-write"
  description = "Read-write access to ${var.project_name} S3 buckets"
  policy      = data.aws_iam_policy_document.read_write.json
  
  tags = local.common_tags
}



# Admin Policy Document
data "aws_iam_policy_document" "admin" {
  statement {
    sid    = "FullAccess"
    effect = "Allow"
    
    actions = ["s3:*"]
    
    resources = [
      aws_s3_bucket.raw_data.arn,
      "${aws_s3_bucket.raw_data.arn}/*",
      aws_s3_bucket.processed_data.arn,
      "${aws_s3_bucket.processed_data.arn}/*",
      aws_s3_bucket.models.arn,
      "${aws_s3_bucket.models.arn}/*"
    ]
  }
  
  # Add KMS permissions if encryption is enabled
  dynamic "statement" {
    for_each = var.enable_encryption && var.sse_algorithm == "aws:kms" ? [1] : []
    
    content {
      sid    = "KMSFullAccess"
      effect = "Allow"
      
      actions = ["kms:*"]
      
      resources = [var.kms_key_arn]
    }
  }
}

# Create the admin policy
resource "aws_iam_policy" "admin" {
  name        = "${var.project_name}-${var.environment}-s3-admin"
  description = "Admin access to ${var.project_name} S3 buckets"
  policy      = data.aws_iam_policy_document.admin.json
  
  tags = local.common_tags
}


# Bucket Policies (Optional - for cross-account access)
resource "aws_s3_bucket_policy" "cross_account" {
  for_each = {} 
  
  bucket = each.value
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CrossAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = [] 
        }
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          each.value,
          "${each.value}/*"
        ]
      }
    ]
  })
}