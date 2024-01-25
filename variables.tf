variable "project_name" {
  description = "Name of the project."
  type        = string
}

variable "domain_name" {
  description = "Domain name of the project."
  type        = string
}

variable "bucket_name_prefix" {
  description = "Name of the s3 bucket. Must be unique."
  type        = string
}

variable "django_settings_module" {
  type    = string
  default = "config.settings.staging"
}

variable "django_env" {
  type    = string
  default = "staging"
}

variable "rds_port" {
  type    = string
  default = "5432"
}

variable "database_name" {
  type = string
}

variable "docker_tag" {
  type = string
}

variable "secrets_manager_rds_path" {
  type = string
}

variable "secrets_manager_django_secret_path" {
  type = string
}

variable "target_port" {
  description = "exposed target port of the container within the ec2 instance"
  type = number
}