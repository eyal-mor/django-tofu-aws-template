module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = var.project_name

  engine            = "postgres"
  engine_version    = "16.1"
  instance_class    = "db.t4a.small"
  allocated_storage = 30

  db_name  = "${var.project_name}-db"
  username = "user"
  port     = "5432"

  iam_database_authentication_enabled = true

  vpc_security_group_ids = [var.db_sg_ids]

  maintenance_window = "Sat:00:00-Sat:03:00"
  backup_window      = "03:00-06:00"

  # DB subnet group
  create_db_subnet_group = false
  subnet_ids             = var.db_subnet_ids

  # DB parameter group
  family = "postgres16.1"

  # DB option group
  major_engine_version = "16.1"

  # Database Deletion Protection
  deletion_protection = false

  parameters = [
    {
      name  = "idle_in_transaction_session_timeout"
      value = "30000"
    },
  ]


}
