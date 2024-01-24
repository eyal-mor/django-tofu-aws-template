resource "aws_launch_template" "launch_template" {
  name_prefix            = "launch"
  image_id               = "ami-0230bd60aa48260c6"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["sg-08f43c378913683b1"]

  update_default_version = true

  user_data = base64encode(
    templatefile(
      "${path.module}/bin/user-data.tpl",
      {
        DJANGO_SETTINGS_MODULE             = var.django_settings_module
        DJANGO_ENV                         = var.django_env
        RDS_URL                            = var.rds_url
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

  key_name = "Project"

  iam_instance_profile {
    name = "ProjectInsecureRole"
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "Project"
    }
  }
}

resource "aws_autoscaling_group" "asg" {
  availability_zones = ["us-east-1a"]
  desired_capacity   = 1
  max_size           = 2
  min_size           = 1

  name_prefix       = "Project-"
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
