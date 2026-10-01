# ── Comments ──
# Terraform (HCL): warehouse inventory infrastructure, per environment.
// Double-slash comments are accepted too.
/* Block comment
   spanning several lines. */
# TODO: split into modules per service
# FIXME: lifecycle rule expires too early in dev

# ── terraform block ──
terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
    local = {
      source = "hashicorp/local"
    }
  }

  backend "s3" {
    bucket         = "example-terraform-state"
    key            = "inventory/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "example-terraform-locks"
    encrypt        = true
  }
}

# ── Providers ──
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Service     = "inventory"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }

  assume_role {
    role_arn = "arn:aws:iam::123456789012:role/example-deployer"
  }
}

provider "aws" {
  alias  = "replica"
  region = "eu-central-1"
}

# ── Variables ──
variable "environment" {
  type        = string
  description = "dev, staging or prod"
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging or prod."
  }
}

variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "retain_days" {
  type      = number
  default   = 30
  sensitive = false
  nullable  = false
}

variable "enable_versioning" {
  type    = bool
  default = true
}

variable "warehouses" {
  type = map(object({
    capacity = number
    region   = optional(string, "eu-west-1")
    tags     = optional(list(string), [])
  }))
  default = {
    north = { capacity = 5000 }
    south = { capacity = 3000, region = "eu-west-2", tags = ["cold", "bulk"] }
  }
}

variable "allowed_cidrs" {
  type    = list(string)
  default = ["192.0.2.0/24", "198.51.100.0/24"]
}

variable "labels" {
  type    = set(string)
  default = ["a", "b"]
}

variable "pair" {
  type    = tuple([string, number, bool])
  default = ["x", 1, true]
}

variable "anything" {
  type    = any
  default = null
}

variable "api_token" {
  type      = string
  sensitive = true
  default   = "example-not-a-real-token"
  ephemeral = false
}

# ── Locals ──
locals {
  bucket_name = "inventory-uploads-${var.environment}"
  retain_days = var.environment == "prod" ? 365 : var.retain_days
  common_tags = merge(
    { Environment = var.environment },
    { for k, v in var.warehouses : "warehouse-${k}" => v.capacity }
  )
  names       = [for w in keys(var.warehouses) : upper(w)]
  big         = [for k, v in var.warehouses : k if v.capacity > 4000]
  by_region   = { for k, v in var.warehouses : v.region => k... }
  flattened   = flatten([for w in var.warehouses : w.tags])
  first_cidr  = var.allowed_cidrs[0]
  last_cidr   = element(var.allowed_cidrs, length(var.allowed_cidrs) - 1)
  total       = sum([for w in var.warehouses : w.capacity])
  upper_env   = upper(var.environment)
  has_prefix  = startswith(local.bucket_name, "inventory")
  json_doc    = jsonencode({ name = "inventory", ports = [80, 443], enabled = true })
  yaml_doc    = yamlencode({ list = [1, 2, 3] })
  encoded     = base64encode("example")
  hashed      = sha256("example")
  formatted   = format("%s-%03d", "ABC", 7)
  joined      = join(", ", local.names)
  splatted    = [for w in aws_s3_bucket.uploads : w.id]
  conditional = var.enable_versioning && !(var.environment == "dev") || false
  arithmetic  = 1 + 2 - 3 * 4 / 5 % 6
  negated     = -local.total
  comparison  = 1 < 2 && 2 <= 3 && 3 > 2 && 3 >= 3 && 1 != 2
  numbers     = [42, -7, 3.14, 1.5e10, 2E-3, 0xFF]
  nothing     = null
}

# ── Heredocs and strings ──
locals {
  plain       = "plain string"
  escaped     = "tab\t newline\n quote\" backslash\\ unicodeé \U0001F3ED"
  literal_dollar = "$${not_interpolated} and %%{not_a_directive}"
  interpolated = "env=${var.environment} total=${local.total + 1} upper=${upper("abc")}"
  nested      = "outer ${join("-", ["a", "${var.region}", "c"])}"
  directive   = "%{ if var.enable_versioning }versioned%{ else }plain%{ endif }"
  loop_text   = "%{ for name in local.names }${name},%{ endfor }"
  strip_text  = "%{~ for name in local.names ~}\n${name}\n%{~ endfor ~}"

  policy = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow", "Action": "s3:GetObject", "Resource": "arn:aws:s3:::${local.bucket_name}/*" }
  ]
}
EOT

  indented = <<-EOT
    Indented heredoc for ${var.environment}.
      Inner indentation is kept relative.
    %{ for n in local.names ~}
    - ${n}
    %{ endfor ~}
    EOT
}

# ── Data sources ──
data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_iam_policy_document" "uploads" {
  statement {
    sid       = "AllowRead"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [aws_s3_bucket.uploads["north"].arn, "${aws_s3_bucket.uploads["north"].arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.arn]
    }

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = var.allowed_cidrs
    }
  }
}

# ── Resources ──
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "uploads" {
  for_each = var.warehouses

  bucket = "${local.bucket_name}-${each.key}-${random_id.suffix.hex}"
  tags   = merge(local.common_tags, { Warehouse = each.key, Capacity = each.value.capacity })

  lifecycle {
    prevent_destroy       = false
    create_before_destroy = true
    ignore_changes        = [tags["LastScan"], tags_all]
    replace_triggered_by  = [random_id.suffix]

    precondition {
      condition     = each.value.capacity > 0
      error_message = "capacity must be positive."
    }

    postcondition {
      condition     = self.bucket != ""
      error_message = "bucket name must not be empty."
    }
  }
}

resource "aws_s3_bucket_versioning" "uploads" {
  for_each = aws_s3_bucket.uploads
  bucket   = each.value.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "uploads" {
  count  = length(local.names)
  bucket = values(aws_s3_bucket.uploads)[count.index].id

  rule {
    id     = "expire-old-${count.index}"
    status = "Enabled"

    filter {}

    expiration {
      days = local.retain_days
    }

    dynamic "transition" {
      for_each = var.environment == "prod" ? [30, 90] : []
      iterator = tier

      content {
        days          = tier.value
        storage_class = tier.key == 0 ? "STANDARD_IA" : "GLACIER"
      }
    }
  }
}

resource "aws_s3_bucket_policy" "uploads" {
  bucket     = aws_s3_bucket.uploads["north"].id
  policy     = data.aws_iam_policy_document.uploads.json
  depends_on = [aws_s3_bucket_versioning.uploads]
}

resource "aws_security_group" "api" {
  name_prefix = "inventory-api-"
  provider    = aws.replica

  dynamic "ingress" {
    for_each = toset([80, 443])
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidrs
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  provisioner "local-exec" {
    command    = "echo ${self.id} >> ids.txt"
    when       = create
    on_failure = continue
  }

  connection {
    type = "ssh"
    host = "192.0.2.10"
  }
}

# ── Modules ──
module "network" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "inventory-${var.environment}"
  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)

  providers = {
    aws = aws.replica
  }
}

module "local_example" {
  source     = "./modules/queue"
  count      = var.environment == "prod" ? 1 : 0
  queue_name = "orders-${var.environment}"
  depends_on = [module.network]
}

# ── Moved, import, removed, check ──
moved {
  from = aws_s3_bucket.old_uploads
  to   = aws_s3_bucket.uploads["north"]
}

import {
  to = aws_s3_bucket.uploads["south"]
  id = "inventory-uploads-legacy"
}

removed {
  from = aws_s3_bucket.legacy

  lifecycle {
    destroy = false
  }
}

check "health" {
  data "http" "api" {
    url = "https://example.com/healthz"
  }

  assert {
    condition     = data.http.api.status_code == 200
    error_message = "API health check failed."
  }
}

# ── Functions and expressions showcase ──
output "bucket_names" {
  description = "Names of all upload buckets."
  value       = { for k, b in aws_s3_bucket.uploads : k => b.bucket }
}

output "first_bucket_arn" {
  value = values(aws_s3_bucket.uploads)[0].arn
}

output "all_ids" {
  value = aws_s3_bucket.uploads[*].id
}

output "api_token" {
  value     = var.api_token
  sensitive = true
}

output "summary" {
  value = {
    account  = data.aws_caller_identity.current.account_id
    count    = length(aws_s3_bucket.uploads)
    lookup   = lookup(var.warehouses, "north", { capacity = 0 })["capacity"]
    try_it   = try(var.warehouses["west"].capacity, -1)
    can_it   = can(regex("^inventory-", local.bucket_name))
    coalesce = coalesce(var.anything, "fallback")
    one      = one([])
    timeadd  = timeadd("2026-09-24T00:00:00Z", "24h")
    cidr     = cidrsubnet("10.0.0.0/16", 8, 1)
    file     = fileexists("${path.module}/README.md") ? file("${path.module}/README.md") : ""
    paths    = [path.root, path.cwd, path.module]
    ws       = terraform.workspace
    self_ref = "${var.environment}-${local.upper_env}"
  }
  depends_on = [aws_s3_bucket_policy.uploads]
  precondition {
    condition     = length(aws_s3_bucket.uploads) > 0
    error_message = "at least one bucket is required."
  }
}
