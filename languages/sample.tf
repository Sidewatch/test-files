# Terraform: an S3 bucket with versioning and a lifecycle rule, per environment.
terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.60" }
  }
}

variable "environment" {
  type        = string
  description = "dev, staging or prod"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging or prod."
  }
}

locals {
  bucket_name = "inventory-uploads-${var.environment}"
  retain_days = var.environment == "prod" ? 365 : 30
}

resource "aws_s3_bucket" "uploads" {
  bucket = local.bucket_name
  tags   = { Environment = var.environment, Service = "inventory" }
}

resource "aws_s3_bucket_versioning" "uploads" {
  bucket = aws_s3_bucket.uploads.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_lifecycle_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id
  rule {
    id     = "expire-old"
    status = "Enabled"
    expiration { days = local.retain_days }
  }
}

output "bucket_arn" { value = aws_s3_bucket.uploads.arn }
