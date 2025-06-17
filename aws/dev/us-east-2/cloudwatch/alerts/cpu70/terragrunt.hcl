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
  path   = find_in_parent_folders("_env/cw_alerts.hcl")
  expose = true
}

# ---------------------------------------------------------------------------------------------------------------------
# Dependencies
# ---------------------------------------------------------------------------------------------------------------------

dependency "ecs_service" {
  config_path = find_in_parent_folders("ecs")

  mock_outputs = {
    cluster_name = "cluster-name"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Local Variables
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# Override parameters for this environment
# ---------------------------------------------------------------------------------------------------------------------

inputs = {
  alarm_name          = "HighCPUUtilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Triggered when ECS CPU > 70%"
  dimensions = {
    ClusterName = dependency.ecs_service.outputs.cluster_name
  }
  treat_missing_data = "missing"

  tags = include.root.locals.tags
}
