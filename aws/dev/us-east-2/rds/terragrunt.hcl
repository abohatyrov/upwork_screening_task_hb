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
  path   = find_in_parent_folders("_env/rds.hcl")
  expose = true
}

# ---------------------------------------------------------------------------------------------------------------------
# Dependencies
# ---------------------------------------------------------------------------------------------------------------------

dependency "vpc" {
  config_path = find_in_parent_folders("vpc")

  mock_outputs = {
    vpc_id          = "vpc-xxxxxxxxxxxxxxxxxxxx"
    private_subnets = [
      "subnet0",
      "subnet1"
    ]
  }
}

dependency "sg" {
  config_path = find_in_parent_folders("security_groups/rds")

  mock_outputs = {
    security_group_id = "sg-xxxxxxxxxxxxxxxxxxxx"
  }
}

dependency "root_password" {
  config_path = find_in_parent_folders("random_pwd/rds_master_pwd")

  mock_outputs = {
    result = "strong-password"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Local Variables
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# Override parameters for this environment
# ---------------------------------------------------------------------------------------------------------------------

inputs = {
  identifier = "${include.root.locals.common_prefix}-db-01"

  engine               = "postgres"
  engine_version       = "15.4"
  instance_class       = "db.t4g.micro"
  family               = "postgres15"
  allocated_storage    = 20
  storage_encrypted    = true
  publicly_accessible  = false

  vpc_security_group_ids = [dependency.sg.outputs.security_group_id]
  subnet_ids             = dependency.vpc.outputs.private_subnets

  db_name  = "spring-db"
  username = "admin"
  password = dependency.root_password.outputs.result
  port     = 5432

  multi_az                = true
  backup_retention_period = 7
  skip_final_snapshot     = true

  tags = merge(
    include.root.locals.tags,
    {
      Name = "${include.root.locals.common_prefix}-rds"
    }
  )
}
