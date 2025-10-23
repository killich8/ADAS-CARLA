# RDS Subnet Group for database subnets
# This allows RDS instances to be deployed across multiple AZs

resource "aws_db_subnet_group" "database" {
  count = length(var.database_subnets) > 0 ? 1 : 0

  name        = "${var.name}-${var.environment}-db-subnet-group"
  description = "Database subnet group for ${var.name}-${var.environment}"
  subnet_ids  = aws_subnet.database[*].id

  tags = merge(
    var.tags,
    {
      Name        = "${var.name}-${var.environment}-db-subnet-group"
      Environment = var.environment
    }
  )
}