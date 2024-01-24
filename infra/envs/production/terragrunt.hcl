include "root" {
  path = find_in_parent_folders()
}

# Indicate what region to deploy the resources into
generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      # Keep this if we want to setup multiple demo environments in the future.
      # Environment = "Demo"
      Project = "Project"
    }
  }
}
EOF
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket = "Project-terraform-state"
    key    = "Project.tfstate"
    region = "us-east-1"
    dynamodb_table = "Project-state-lock"
  }
}

# Indicate the input values to use for the variables of the module.
inputs = {
  bucket_name = "Project"
  local       = false

  secrets_manager_rds_path           = "{FILL_HERE}"
  secrets_manager_django_secret_path = "DJANGO_SECRET_KEY"
  security_group_id = "{FILL_HERE}"
}