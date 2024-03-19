variable "ec2_security_group_id" {
  description = "value of the load balancer security group id"
  type        = string
}

variable "django_env" {
  description = "value of the django environment"
  type        = map(string)
}

variable "project_name" {
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

variable "s3_uploads_bucket_name" {
  type = string
}

variable "s3_static_bucket_name" {
  type = string
}

variable "celery_queue_arn" {
  type = string
}

variable "rds_resource_id" {
  type = string
}

variable "db_user_name" {
  type = string
}

variable "rds_instance_address" {
  type = string
}

variable "docker_registry_url" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "secrets_name" {
  type = string
}

variable "instance_type" {
  description = "Type of the EC2 instance"
  type        = string
}

variable "use_spot_instances" {
  description = "Use spot instances"
  type        = bool
}
