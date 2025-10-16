# Main Terraform configuration


terraform {
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  default = "eu-west-1"
}
