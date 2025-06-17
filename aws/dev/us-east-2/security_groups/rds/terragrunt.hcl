# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# This is the configuration for Terragrunt, a thin wrapper for Terraform that helps keep your code DRY and
# maintainable: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

skip = false

# ---------------------------------------------------------------------------------------------------------------------
# Include configurations that are common used across multiple environments.
# ---------------------------------------------------------------------------------------------------------------------

# Include the root `terragrunt.hcl` configuration. The root configuration contains settings that are common across all
# components and environments, such as how to configure remote state.
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

# Include the envcommon configuration for the component. The envcommon configuration contains settings that are common
# for the component across all environments.
include "envcommon" {
  path   = find_in_parent_folders("_env/security_groups.hcl")
  expose = true
}

# ---------------------------------------------------------------------------------------------------------------------
# Dependencies
# ---------------------------------------------------------------------------------------------------------------------

dependency "vpc" {
  config_path = find_in_parent_folders("vpc")

  mock_outputs = {
    vpc_id = "vpc-xxxxxxxxxxxxxxxxxxxx"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Local Variables
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# Override parameters for this environment
# ---------------------------------------------------------------------------------------------------------------------

inputs = {
  name        = "${include.root.locals.common_prefix}-rds-sg"
  description = "Allow DB access from app"

  vpc_id = dependency.vpc.outputs.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = "10.0.0.0/16"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = include.root.locals.tags
}
