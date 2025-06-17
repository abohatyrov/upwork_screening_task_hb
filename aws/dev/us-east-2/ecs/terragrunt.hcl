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
  path   = find_in_parent_folders("_env/ecs.hcl")
  expose = true
}

# ---------------------------------------------------------------------------------------------------------------------
# Dependencies
# ---------------------------------------------------------------------------------------------------------------------

dependency "vpc" {
  config_path = find_in_parent_folders("vpc")

  mock_outputs = {
    vpc_id         = "vpc-xxxxxxxxxxxxxxxxxxxx"
    private_subnets = [
      "subnet0",
      "subnet1"
    ]
  }
}

dependency "sg" {
  config_path = find_in_parent_folders("security_groups/ecs")

  mock_outputs = {
    security_group_id = "sg-xxxxxxxxxxxxxxxxxxxx"
  }
}

dependency "alb" {
  config_path = find_in_parent_folders("alb")

  mock_outputs = {
    target_groups = {
      ex-target = {
        arn = "arn:aws:test::test-target-group"
      }
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Local Variables
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# Override parameters for this environment
# ---------------------------------------------------------------------------------------------------------------------

inputs = {
  name         = "${include.root.locals.common_prefix}-ecs"
  cluster_name = "${include.root.locals.common_prefix}-cluster"
  create_cluster = true

  fargate_services = {
    nginx = {
      cpu               = 256
      memory            = 512
      desired_count     = 1
      subnet_ids        = dependency.vpc.outputs.private_subnets
      security_groups   = [dependency.sg.outputs.security_group_id]
      assign_public_ip  = false

      load_balancer = {
        target_group_arn = dependency.alb.outputs.target_groups["ex-target"].arn
        container_name   = "nginx"
        container_port   = 80
      }

      container_definitions = [
        {
          name      = "nginx"
          image     = "nginx:latest"
          cpu       = 256
          memory    = 512
          essential = true
          port_mappings = [
            {
              containerPort = 80
              hostPort      = 80
              protocol      = "tcp"
            }
          ]
          log_configuration = {
            log_driver = "awslogs"
            options = {
              awslogs-group         = "/ecs/nginx"
              awslogs-region        = include.root.locals.aws_region
              awslogs-stream-prefix = "ecs"
            }
          }
        }
      ]
    }
  }

  tags = include.root.locals.tags
}
