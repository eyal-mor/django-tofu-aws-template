variable "private_route_table_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "project_name" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "use_spot_instances" {
  type = bool
  default = true
}
