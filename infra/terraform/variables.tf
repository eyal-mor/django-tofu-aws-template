variable "bucket_name" {
  description = "Name of the s3 bucket. Must be unique."
  type        = string
}

variable "tags" {
  description = "Tags to set on the bucket."
  type        = map(string)
  default     = {}
}

variable "local" {
  type    = bool
  default = true
}

variable "django_settings_module" {
  type    = string
  default = "config.settings.staging"
}

variable "django_env" {
  type    = string
  default = "staging"
}

variable "rds_url" {
  type    = string
  default = ""
}

variable "rds_port" {
  type    = string
  default = "5432"
}

variable "database_name" {
  type    = string
  default = "Project"
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

variable "security_group_id" {
  type = string
}