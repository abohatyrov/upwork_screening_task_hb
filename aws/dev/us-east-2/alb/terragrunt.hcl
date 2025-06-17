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
  path   = find_in_parent_folders("_env/alb.hcl")
  expose = true
}

# ---------------------------------------------------------------------------------------------------------------------
# Dependencies
# ---------------------------------------------------------------------------------------------------------------------

dependency "vpc" {
  config_path = find_in_parent_folders("vpc")

  mock_outputs = {
    vpc_id         = "vpc-xxxxxxxxxxxxxxxxxxxx"
    public_subnets = [
      "subnet0",
      "subnet1"
    ]
  }
}

dependency "sg" {
  config_path = find_in_parent_folders("security_groups/alb")

  mock_outputs = {
    security_group_id = "sg-xxxxxxxxxxxxxxxxxxxx"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Local Variables
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# Override parameters for this environment
# ---------------------------------------------------------------------------------------------------------------------

inputs = {
  name               = "${include.root.locals.common_prefix}-alb-01"
  load_balancer_type = "application"

  vpc_id          = dependency.vpc.outputs.vpc_id
  subnets         = dependency.vpc.outputs.public_subnets
  security_groups = [dependency.sg.outputs.security_group_id]

  target_groups = {
    ex-target = {
      name_prefix      = "ng"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "ip"
      target_id        = "10.0.1.10"
      health_check = {
        path                = "/"
        matcher             = "200"
        interval            = 30
        healthy_threshold   = 2
        unhealthy_threshold = 2
      }
    }
  }

  listeners = {
    ex-http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "ex-target"
      }
    }
  }

  tags = include.root.locals.tags
}
