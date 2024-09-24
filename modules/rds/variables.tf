variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "db_subnet_ids" {
  description = "Subnet ids for the database"
  type        = list(string)
}

variable "db_sg_ids" {
  description = "value of the db security group id"
  type        = list(string)
}

variable "enable_db_backups" {
  description = "Enable automated backups for the database"
  type        = bool
}
