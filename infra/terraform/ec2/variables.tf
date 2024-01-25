variable "vpc_id" {
  description = "VPC id"
  type        = string
}

variable "load_balancer_security_group_id" {
  description = "value of the load balancer security group id"
  type = string
}

variable "target_port" {
  description = "value of the target port"
  type = number
}


variable "django_settings_module" {
  type = string
}

variable "project_name" {
  type = string
}

variable "django_env" {
  type = string
}

variable "rds_port" {
  type = string
}

variable "secrets_manager_rds_path" {
  type = string
}

variable "secrets_manager_django_secret_path" {
  type = string
}

variable "database_name" {
  type = string
}

variable "compose_file" {
  type = string
}

variable "target_group_arns" {
  type = list(string)
}