variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "db_subnet_ids" {
  description = "Subnet ids for the database"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC id"
  type        = string
}

variable "private_network_cidrs" {
  description = "Private network CIDRs"
  type        = list(string)
}