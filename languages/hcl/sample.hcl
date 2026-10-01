# HCL2 (Terraform 1.14, Nomad 1.10) — syntax showcase
# ── Comments ──
# HCL: Terraform and Nomad style configuration for the inventory API.
// Double-slash comments are valid too.
/* Block comment
   spanning lines. TODO: split into modules. FIXME: drift. */

# ── Terraform settings and providers ──
terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source = "hashicorp/random"
    }
  }

  backend "s3" {
    bucket = "acme-terraform-state"
    key    = "inventory/terraform.tfstate"
    region = "eu-west-1"
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = local.common_tags
  }
}

# ── Variables with types, defaults, validation ──
variable "region" {
  type        = string
  description = "AWS region to deploy into."
  default     = "eu-west-1"
}

variable "instance_count" {
  type    = number
  default = 3

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "The instance count must be between 1 and 10."
  }
}

variable "enable_tls" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = { team = "warehouse", tier = "backend" }
}

variable "subnets" {
  type    = list(string)
  default = ["subnet-a", "subnet-b"]
}

variable "settings" {
  type = object({
    name    = string
    retries = optional(number, 3)
    ports   = list(number)
  })
  sensitive = true
}

variable "any_value" {
  type    = any
  default = null
}

# ── Locals ──
locals {
  common_tags = merge(var.tags, { environment = terraform.workspace })
  name_prefix = "inventory-${terraform.workspace}"
  port_map    = { for idx, port in [80, 443] : "port-${idx}" => port }
  doubled     = [for n in [1, 2, 3] : n * 2 if n != 2]
  upper_names = [for s in var.subnets : upper(s)]
  nested      = { a = { b = { c = 1 } } }
}

# ── Literals and expressions ──
locals {
  integer     = 42
  negative    = -17
  decimal     = 3.14
  exponent    = 6.02e23
  boolean     = true
  nothing     = null
  string_lit  = "double \"quoted\" with \\ backslash, \n newline, \t tab, é, \U0001F600"
  interpolate = "Hello, ${var.region} and ${upper("x")} $${escaped} %%{escaped}"
  directive   = "%{ if var.enable_tls }secure%{ else }plain%{ endif }"
  loop_dir    = "%{ for s in var.subnets }${s},%{ endfor }"
  tern        = var.enable_tls ? "https" : "http"
  arith       = (1 + 2) * 3 - 4 / 2 % 3
  compare     = 1 < 2 && 2 <= 3 || 3 > 2 && !(3 >= 3) || 1 == 1 && 1 != 2
  index       = var.subnets[0]
  attr        = var.tags.team
  splat       = aws_instance.web[*].id
  legacy_splat = aws_instance.web.*.id
  func_call   = length(var.subnets) + max(1, 2, 3)
  coalesced   = coalesce(var.any_value, "fallback")
  try_val     = try(local.nested.a.b.c, 0)
  fmt         = format("%s-%03d", local.name_prefix, 7)
  json        = jsonencode({ name = "inventory", ports = [80, 443] })
  file_read   = file("${path.module}/config.json")
  heredoc     = <<EOT
Heredoc with ${local.name_prefix}
  and $${escaped} text
EOT
  heredoc_indented = <<-EOT
    Indented heredoc keeps relative
      indentation and trims the common prefix.
    Value: ${var.region}
  EOT
  raw_heredoc = <<'EOT'
No ${interpolation} here.
EOT
}

# ── Resources, data sources, modules ──
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*"]
  }
}

resource "aws_instance" "web" {
  count         = var.instance_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = element(var.subnets, count.index)

  tags = {
    Name = "${local.name_prefix}-${count.index}"
  }

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
    ignore_changes        = [tags, ami]
  }

  dynamic "ebs_block_device" {
    for_each = var.enable_tls ? [1] : []
    content {
      device_name = "/dev/sdb"
      volume_size = 20
    }
  }

  depends_on = [aws_security_group.web]
}

resource "aws_security_group" "web" {
  for_each = toset(["http", "https"])
  name     = "${local.name_prefix}-${each.key}"

  provisioner "local-exec" {
    command = "echo ${self.id}"
  }
}

module "network" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  cidr = "10.0.0.0/16"
}

output "instance_ids" {
  value       = aws_instance.web[*].id
  description = "IDs of the web instances."
  sensitive   = false
}

moved {
  from = aws_instance.old
  to   = aws_instance.web
}

import {
  to = aws_instance.web[0]
  id = "i-0123456789abcdef0"
}

check "health" {
  assert {
    condition     = length(aws_instance.web) > 0
    error_message = "No instances."
  }
}

# ── Nomad job (same syntax) ──
job "inventory-api" {
  datacenters = ["dc1"]
  type        = "service"

  update {
    max_parallel     = 1
    min_healthy_time = "30s"
    auto_revert      = true
  }

  group "api" {
    count = 3

    network {
      port "http" { to = 8080 }
    }

    service {
      name = "inventory-api"
      port = "http"
      check {
        type     = "http"
        path     = "/healthz"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "server" {
      driver = "docker"
      config {
        image = "registry.example.com/inventory:1.4.0"
        ports = ["http"]
      }
      env {
        LOG_LEVEL = "info"
        DB_URL    = "${NOMAD_META_db_url}"
      }
      resources { cpu = 500, memory = 256 }
    }
  }
}

# ── More Terraform block types and meta-arguments ──
terraform {
  cloud {
    organization = "acme"
    workspaces {
      tags = ["inventory"]
    }
  }

  experiments = [module_variable_optional_attrs]

  provider_meta "aws" {
    module_name = "inventory"
  }
}

provider "aws" {
  alias   = "west"
  region  = "us-west-2"
  profile = "example-profile"
  assume_role {
    role_arn     = "arn:aws:iam::123456789012:role/example"
    session_name = "terraform"
  }
}

variable "nullable_example" {
  type      = string
  nullable  = false
  ephemeral = true
  default   = "x"
  description = <<-DESC
    Heredoc description
    over lines.
  DESC
}

resource "aws_s3_bucket" "logs" {
  provider = aws.west
  bucket   = "acme-logs-${random_id.suffix.hex}"

  lifecycle {
    precondition {
      condition     = var.enable_tls
      error_message = "TLS must be on."
    }
    postcondition {
      condition     = self.bucket != ""
      error_message = "Bucket name is empty."
    }
    replace_triggered_by = [aws_instance.web[0].id, random_id.suffix]
  }

  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue
    inline     = ["echo bye", "sudo systemctl stop app"]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ubuntu"
      private_key = file("~/.ssh/example_key")
      timeout     = "5m"
    }
  }
}

resource "terraform_data" "marker" {
  input            = timestamp()
  triggers_replace = [var.region]
}

removed {
  from = aws_instance.legacy
  lifecycle {
    destroy = false
  }
}

# ── Expressions: splats, indexes, for with grouping, conditionals, functions ──
locals {
  first_id      = aws_instance.web[0].id
  all_ids       = aws_instance.web[*].id
  nested_splat  = aws_instance.web[*].tags["Name"]
  full_splat    = aws_instance.web.*.tags.Name
  legacy_index  = aws_instance.web.0.id
  attr_index    = var.tags["team"]
  quoted_attr   = var.tags.team
  grouped       = { for k, v in var.tags : v => k... }
  filtered      = { for k, v in var.tags : k => upper(v) if v != "backend" }
  tuple_for     = [for i, s in var.subnets : "${i}:${s}"]
  nested_for    = [for a in [1, 2] : [for b in [3, 4] : a * b]]
  cond_chain    = var.instance_count > 5 ? "large" : var.instance_count > 2 ? "medium" : "small"
  safe_lookup   = lookup(var.tags, "missing", "default")
  can_check     = can(regex("^[a-z]+$", var.region))
  templated     = templatefile("${path.module}/user_data.sh.tpl", { region = var.region, ports = [80, 443] })
  paths         = [path.root, path.module, path.cwd, terraform.workspace]
  each_example  = { for s in toset(var.subnets) : s => length(s) }
  multi_line_call = merge(
    local.common_tags,
    { extra = "tag" },
    {
      another = "tag"
    },
  )
  multi_line_cond = (
    var.enable_tls
    && var.instance_count > 1
    || var.region == "eu-west-1"
  )
  strip_markers = <<-EOT
    %{~ for s in var.subnets ~}
    subnet: ${~ s ~}
    %{~ endfor ~}
  EOT
  conditional_directive = "%{if var.enable_tls}tls%{else}plain%{endif}"
  nested_interp = "a ${"b ${"c ${1 + 1}"}"} d"
  escaped_all   = "$${not} %%{not} \\$ \" \n \r \t \\ \u0041 \U0001F600"
  numbers       = [0, -1, 1.5, 1e3, 1E-3, 0.5e+2]
  keywords      = [true, false, null]
  reference_kw  = [var.region, local.name_prefix, data.aws_ami.ubuntu.id, module.network.vpc_id, each.key, each.value, count.index, self.id, path.module, terraform.workspace]
}

# ── Consul, Vault and Packer flavoured HCL ──
service {
  name = "web"
  port = 80
  check {
    http     = "http://localhost:80/health"
    interval = "10s"
  }
}

path "secret/data/inventory/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
  allowed_parameters = {
    "foo" = []
    "bar" = ["baz"]
  }
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "inventory-${formatdate("YYYYMMDD", timestamp())}"
  instance_type = "t3.micro"
  region        = "eu-west-1"
  source_ami_filter {
    filters = {
      name = "ubuntu/images/*"
    }
    most_recent = true
  }
}

build {
  sources = ["source.amazon-ebs.ubuntu"]
  provisioner "shell" {
    inline = ["echo hello"]
  }
  post-processor "manifest" {
    output = "manifest.json"
  }
}

# Single-line block and non-ASCII value
settings { enabled = true }
unicode_key = "café 日本語 ☕"

# ── Terraform 1.8–1.14: ephemeral resources, write-only attributes, actions, provider functions ──
ephemeral "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
}

resource "aws_db_instance" "main" {
  identifier          = "inventory"
  engine              = "postgres"
  username            = "inventory"
  password_wo         = ephemeral.aws_secretsmanager_secret_version.db.secret_string
  password_wo_version = 1

  lifecycle {
    action_trigger {
      events  = [after_create, after_update]
      actions = [action.aws_lambda_invoke.notify]
    }
  }
}

action "aws_lambda_invoke" "notify" {
  config {
    function_name = "notify-ops"
    payload       = jsonencode({ event = "database-ready" })
  }
}

variable "api_token" {
  type      = string
  ephemeral = true
  sensitive = true
}

locals {
  arn_parts   = provider::aws::arn_parse("arn:aws:iam::123456789012:role/example")
  rendered    = templatestring("Hello ${name}", { name = "inventory" })
  prefix_ok   = startswith(var.region, "eu-") && endswith(var.region, "-1") && strcontains(var.region, "west")
  nullable    = ephemeralasnull(var.api_token)
  applying    = terraform.applying
  lookups     = one(aws_instance.web[*].id)
  sensitive_v = sensitive("hidden")
  nonsens     = nonsensitive(var.settings).name
  type_conv   = [tostring(1), tonumber("2"), tobool("true"), tolist(["a"]), toset(["a"]), tomap({ a = 1 })]
  collections = [flatten([[1], [2]]), distinct([1, 1]), concat([1], [2]), slice([1, 2, 3], 0, 2), zipmap(["a"], [1]), transpose({ a = ["x"] })]
  strings     = [trimspace(" x "), replace("a-b", "-", "_"), regex("[a-z]+", "abc1"), regexall("[0-9]", "a1b2"), split(",", "a,b"), join("-", ["a", "b"]), substr("abcdef", 1, 3), title("hi"), lower("A"), upper("a")]
  encoding    = [base64encode("x"), base64decode("eA=="), urlencode("a b"), yamlencode({ a = 1 }), yamldecode("a: 1"), jsondecode("{\"a\":1}"), md5("x"), sha256("x"), uuid(), cidrsubnet("10.0.0.0/16", 8, 1)]
  numeric     = [abs(-1), ceil(1.2), floor(1.8), min(1, 2), max(1, 2), parseint("ff", 16), pow(2, 3), signum(-5), log(8, 2)]
  time        = [timestamp(), timeadd("2026-01-01T00:00:00Z", "24h"), formatdate("YYYY-MM-DD", timestamp()), plantimestamp()]
  fs          = [abspath(path.root), basename("/a/b"), dirname("/a/b"), pathexpand("~"), fileexists("x"), filebase64("x"), fileset(path.module, "*.tf")]
}

module "per_env" {
  source     = "./modules/env"
  for_each   = toset(["dev", "prod"])
  name       = each.key
  providers  = { aws = aws.west }
  depends_on = [module.network]
}

import {
  for_each = { a = "i-aaa", b = "i-bbb" }
  to       = aws_instance.imported[each.key]
  id       = each.value
}

# ── Terraform query files (.tfquery.hcl) and test files (.tftest.hcl) ──
list "aws_instance" "all" {
  provider = aws
  config {
    region = "eu-west-1"
  }
}

run "validate_instance_count" {
  command = plan
  variables {
    instance_count = 3
  }
  assert {
    condition     = length(aws_instance.web) == 3
    error_message = "Expected three instances."
  }
  expect_failures = [var.instance_count]
}

mock_provider "aws" {
  mock_resource "aws_instance" {
    defaults = { id = "i-mock" }
  }
}

# ── Nomad additions ──
job "batch" {
  type = "batch"
  periodic {
    crons            = ["*/15 * * * *"]
    prohibit_overlap = true
  }
  group "g" {
    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }
    volume "data" {
      type   = "host"
      source = "inventory-data"
    }
    task "t" {
      driver = "exec"
      config {
        command = "/bin/echo"
        args    = ["hello", "${NOMAD_ALLOC_ID}"]
      }
      template {
        data        = <<-EOT
          {{ with secret "secret/data/inventory" }}{{ .Data.data.key }}{{ end }}
        EOT
        destination = "local/secrets.env"
        env         = true
      }
      vault { policies = ["inventory"] }
    }
  }
}
