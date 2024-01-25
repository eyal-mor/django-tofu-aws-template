variable "project_name" {
  description = "value of the project name"
  type = string
}

variable "domain_name" {
  description = "value of the domain name"
  type = string
}

variable "subnet_ids" {
  description = "value of the subnet ids"
  type = list(string)
}

variable "vpc_id" {
  description = "value of the vpc id"
  type = string
}

variable "public_cidr_blocks" {
  description = "value of the private network cidrs"
  type = list(string)
}

variable "ec2_security_group_id" {
  description = "value of the ec2 security group id"
  type = string
}

variable "target_port" {
  description = "value of the target port"
  type = number
}
