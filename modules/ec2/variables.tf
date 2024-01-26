variable "vpc_id" {
  description = "VPC id"
  type        = string
}

variable "ec2_security_group_id" {
  description = "value of the load balancer security group id"
  type        = string
}

variable "target_port" {
  description = "value of the target port"
  type        = number
}

variable django_env {
  description = "value of the django environment"
  type        = map(string, string)
}

variable "project_name" {
  type = string
}

variable "rds_port" {
  type = string
}

variable "compose_file" {
  type = string
}

variable "target_group_arns" {
  type = list(string)
}

variable "s3_uploads_bucket_arn" {
  type = string
}

variable "s3_static_bucket_arn" {
  type = string
}

variable "celery_queue_arn" {
  type = string
}
