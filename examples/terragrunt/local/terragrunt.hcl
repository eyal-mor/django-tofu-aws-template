include "root" {
  path = find_in_parent_folders()
}

# Indicate what region to deploy the resources into
generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "fake"
  secret_key                  = "fake"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3 = "http://s3.localhost.localstack.cloud:4566"
    sqs = "http://localstack:4566"
  }
}
EOF
}

remote_state {
  backend = "local"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {}
}

# Indicate the input values to use for the variables of the module.
inputs = {
  bucket_name = "Project"
  docker_tag="mock"
  secrets_manager_django_secret_path="mock"
  secrets_manager_rds_path="mock"
  security_group_id="mock"
  local       = true
}
