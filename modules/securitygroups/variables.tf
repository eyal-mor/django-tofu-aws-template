variable "project_name" {
  description = "value of the project name"
  type        = string
}

variable "vpc_id" {
  description = "value of the vpc id"
  type        = string
}

variable "private_cidr_blocks" {
  description = "value of the private network cidrs"
  type        = list(string)
}
