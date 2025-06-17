# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# Terragrunt is a thin wrapper for Terraform that provides extra tools for working with multiple Terraform modules,
# remote state, and locking: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

locals {
  common       = yamldecode(file(find_in_parent_folders("configs/common.yaml")))
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  location_vars  = read_terragrunt_config(find_in_parent_folders("location.hcl"))

  aws_account_prefix = local.location_vars.locals.aws_account_prefix
  environment        = local.env_vars.locals.environment
  aws_account_id     = local.env_vars.locals.account_id
  aws_region         = local.region_vars.locals.aws_region

  common_prefix   = "${local.common.project}-${local.common.product}-${local.environment}"

  tags = merge(
    local.common.tags,
    {
      Environment = local.environment == "prod" ? "PROD" : "NONPROD"
    }
  )

  role_arn        = "arn:${local.aws_account_prefix}:iam::${local.aws_account_id}:role/${local.common_prefix}-terragrunt"
  tf_state_bucket = "${local.common_prefix}-${local.aws_region}-tf-state"
}

generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "aws" {
  region = "${local.aws_region}"
  allowed_account_ids = ["${local.aws_account_id}"]
  assume_role {
    role_arn = "${local.role_arn}"
    duration = "1h"
  }
}
EOF
}

# Configure Terragrunt to automatically store tfstate files in an Storage bucket
remote_state {
  backend  = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = local.tf_state_bucket
    key            = "terragrunt/${path_relative_to_include()}/terraform.tfstate"
    region         = "${local.aws_region}"
    encrypt        = true
    use_lockfile   = true
    assume_role    = {
      role_arn = "${local.role_arn}"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# GLOBAL PARAMETERS
# These variables apply to all configurations in this subfolder. These are automatically merged into the child
# `terragrunt.hcl` config via the include block.
# ---------------------------------------------------------------------------------------------------------------------

# Skip creating tfstate file for root folder
skip = true

# Enforce Terraform and Terragrunt version constraints
terraform_version_constraint  = "= ${file(".terraform-version")}"
terragrunt_version_constraint = "= ${file(".terragrunt-version")}"

# Store downloads outside the working directory
download_dir = "${get_repo_root()}/.terragrunt-cache"
