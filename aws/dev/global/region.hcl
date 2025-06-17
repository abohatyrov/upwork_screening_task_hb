locals {
    env_vars       = read_terragrunt_config(find_in_parent_folders("env.hcl"))
    aws_region     = basename(get_terragrunt_dir())
}
