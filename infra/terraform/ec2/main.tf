resource "aws_launch_template" "launch_template" {
  name_prefix            = "launch"
  image_id               = "ami-0230bd60aa48260c6"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [
    aws_security_group.allow_lb.id,
    aws_security_group.allow_db.id,
  ]

  update_default_version = true

  user_data = base64encode(
    templatefile(
      "${path.module}/bin/user-data.tpl",
      {
        DJANGO_SETTINGS_MODULE             = var.django_settings_module
        DJANGO_ENV                         = var.django_env
        RDS_PORT                           = var.rds_port
        SECRETS_MANAGER_RDS_PATH           = var.secrets_manager_rds_path
        SECRETS_MANAGER_DJANGO_SECRET_PATH = var.secrets_manager_django_secret_path
        DATABASE_NAME                      = var.database_name
        # This file is what causes the changes that create a deployment.
        # Without an update on this file, launch config will not update, which won't cause a rolling upgrade.
        compose_file = var.compose_file
      }
    )
  )

  key_name = var.project_name

  iam_instance_profile {
    name = "${var.project_name}InsecureRole"
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project_name}"
    }
  }
}

resource "aws_autoscaling_group" "asg" {
  availability_zones = ["us-east-1a"]
  desired_capacity   = 1
  max_size           = 2
  min_size           = 1

  name_prefix       = "${var.project_name}-"
  target_group_arns = var.target_group_arns

  termination_policies = ["OldestLaunchTemplate", "OldestLaunchConfiguration"]

  instance_refresh {
    strategy = "Rolling"
  }

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = aws_launch_template.launch_template.latest_version
  }
}

resource "aws_security_group" "ec2_in" {
  name        = "${var.project_name}-ec2_in"
  description = "Allows inbound from public network"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = var.target_port
    protocol    = "tcp"
    security_groups = [
      var.load_balancer_security_group_id
    ]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = []
  }
}