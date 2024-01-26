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

variable "django_env" {
  description = "value of the django environment"
  type        = map(string, string)
}

variable "rds_port" {
  type    = string
  default = "5432"
}

variable "docker_tag" {
  type = string
}

variable "target_port" {
  description = "exposed target port of the container within the ec2 instance"
  type        = number
}

variable "vpc_cidr" {
  description = "CIDR of the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "Private subnets of the VPC"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "database_subnets" {
  description = "Private subnets of the VPC"
  type        = list(string)
  default     = ["10.0.201.0/26", "10.0.201.64/26", "10.0.201.128/26"]
}

variable "public_subnets" {
  description = "Public subnets of the VPC"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}
