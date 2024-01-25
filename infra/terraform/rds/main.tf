module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = var.project_name

  engine            = "postgres"
  engine_version    = "16.1"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "${var.project_name}-db"
  username = "user"
  port     = "5432"

  iam_database_authentication_enabled = true

  vpc_security_group_ids = [aws_security_group.allow_db.id]

  maintenance_window = "Fri:00:00-Fri:03:00"
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

  # TODO: Snapshots & Backups support.
}

resource "aws_security_group" "allow_db" {
  name        = "${var.project_name}-allow_db"
  description = "Allows inbound from private network"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = []
    cidr_blocks = var.private_network_cidrs
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  lifecycle {
    create_before_destroy = true
  }
}
