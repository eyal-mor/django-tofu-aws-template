data "aws_iam_policy_document" "assume_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "ec2_instance_role" {
  name               = "${var.project_name}Role"
  assume_role_policy = data.aws_iam_policy_document.assume_policy.json
}


data "aws_iam_policy_document" "policy" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = [
      "${var.s3_uploads_bucket_arn}",
      "${var.s3_uploads_bucket_arn}/*",
      "${var.s3_static_bucket_arn}",
      "${var.s3_static_bucket_arn}/*",
    ]
  }

  statement {
    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ChangeMessageVisibility",
      "sqs:ListQueues",
    ]

    resources = [
      "${var.celery_queue_arn}",
    ]
  }

  statement {
    actions = [
      "rds-db:connect",
    ]

    resources = [
      "${var.rds_instance_arn}",
    ]
  }
}

resource "aws_iam_role_policy" "ec2_instance_role_policy" {
  name = "${var.project_name}RolePolicy"
  role = aws_iam_role.ec2_instance_role.id

  policy = data.aws_iam_policy_document.policy.json
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.project_name}InsecureRole"
  role = aws_iam_role.ec2_instance_role.name
}

resource "aws_launch_template" "launch_template" {
  name_prefix   = "launch"
  image_id      = "ami-0230bd60aa48260c6"
  instance_type = "t2.micro"
  vpc_security_group_ids = [
    var.ec2_security_group_id
  ]

  update_default_version = true

  user_data = base64encode(
    templatefile(
      "${path.module}/bin/user-data.tpl",
      merge(
        var.django_env,
        {
          # This file is what causes the changes that create a deployment.
          # Without an update on this file, launch config will not update, which won't cause a rolling upgrade.
          COMPOSE_FILE = var.compose_file
          RDS_HOST     = var.rds_instance_address
        }
      )
    )
  )

  key_name = var.project_name

  iam_instance_profile {
    name = aws
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