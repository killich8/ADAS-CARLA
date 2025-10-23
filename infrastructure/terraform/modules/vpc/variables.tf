# VPC Module Variables

variable "name" {
  description = "Name to be used on all resources as identifier"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones for subnets"
  type        = list(string)
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = []
}

variable "database_subnets" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Should be true to provision NAT Gateways for each private networks"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Should be true to provision a single shared NAT Gateway across all private networks"
  type        = bool
  default     = false
}

variable "one_nat_gateway_per_az" {
  description = "Should be true to provision one NAT Gateway per availability zone"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs"
  type        = bool
  default     = false
}

variable "flow_logs_retention_days" {
  description = "Retention period for VPC flow logs"
  type        = number
  default     = 7
}

variable "enable_vpn_gateway" {
  description = "Enable a VPN gateway for the VPC"
  type        = bool
  default     = false
}

variable "vpn_gateway_asn" {
  description = "ASN for the VPN gateway"
  type        = number
  default     = 65000
}

# VPC Endpoints
variable "enable_s3_endpoint" {
  description = "Should be true to provision an S3 VPC endpoint"
  type        = bool
  default     = true
}

variable "enable_dynamodb_endpoint" {
  description = "Should be true to provision a DynamoDB VPC endpoint"
  type        = bool
  default     = true
}

variable "enable_ec2_endpoint" {
  description = "Should be true to provision an EC2 VPC endpoint"
  type        = bool
  default     = false
}

variable "enable_ecr_endpoints" {
  description = "Should be true to provision ECR VPC endpoints"
  type        = bool
  default     = false
}

variable "enable_ecs_endpoints" {
  description = "Should be true to provision ECS VPC endpoints"
  type        = bool
  default     = false
}

# Network ACLs
variable "public_dedicated_network_acl" {
  description = "Whether to use dedicated network ACL for public subnets"
  type        = bool
  default     = true
}

variable "private_dedicated_network_acl" {
  description = "Whether to use dedicated network ACL for private subnets"
  type        = bool
  default     = true
}

variable "database_dedicated_network_acl" {
  description = "Whether to use dedicated network ACL for database subnets"
  type        = bool
  default     = true
}

variable "public_inbound_acl_rules" {
  description = "Public subnet inbound network ACL rules"
  type = list(object({
    rule_number = number
    protocol    = string
    rule_action = string
    cidr_block  = string
    from_port   = number
    to_port     = number
  }))
  default = [
    {
      rule_number = 100
      protocol    = "-1"
      rule_action = "allow"
      cidr_block  = "0.0.0.0/0"
      from_port   = 0
      to_port     = 0
    }
  ]
}

variable "public_outbound_acl_rules" {
  description = "Public subnet outbound network ACL rules"
  type = list(object({
    rule_number = number
    protocol    = string
    rule_action = string
    cidr_block  = string
    from_port   = number
    to_port     = number
  }))
  default = [
    {
      rule_number = 100
      protocol    = "-1"
      rule_action = "allow"
      cidr_block  = "0.0.0.0/0"
      from_port   = 0
      to_port     = 0
    }
  ]
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_tags" {
  description = "Additional tags for the VPC"
  type        = map(string)
  default     = {}
}

variable "public_subnet_tags" {
  description = "Additional tags for public subnets"
  type        = map(string)
  default = {
    "kubernetes.io/role/elb" = "1"
  }
}

variable "private_subnet_tags" {
  description = "Additional tags for private subnets"
  type        = map(string)
  default = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

variable "database_subnet_tags" {
  description = "Additional tags for database subnets"
  type        = map(string)
  default = {
    "db-subnet" = "true"
  }
}