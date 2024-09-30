data "aws_region" "current" {}
data "aws_caller_identity" "current_user" {}

data "aws_iam_roles" "roles" {
  name_regex = "AWSReservedSSO_AdministratorAccess_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

resource "random_password" "password" {
  length  = 32
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = var.project_name

  engine            = "postgres"
  engine_version    = "16.3"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  username = "root"
  port     = "5432"

  iam_database_authentication_enabled = true

  vpc_security_group_ids = var.db_sg_ids

  maintenance_window = "Sat:00:00-Sat:03:00"
  backup_window      = "03:00-06:00"
  backup_retention_period = var.enable_db_backups ? 7 : 0

  # IL Central 1 does not support managing master user password with secrets manager
  # https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RDS_Fea_Regions_DB-eng.Feature.SecretsManager.html
  manage_master_user_password = data.aws_region.current.name == "il-central-1" ? false : true
  # If manage_master_user_password is set to false, the master user password is generated and stored in the state file
  password = random_password.password.result

  # DB subnet group
  create_db_subnet_group = true
  subnet_ids             = var.db_subnet_ids

  # DB Family
  family = "postgres16"

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
