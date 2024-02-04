data "aws_region" "current_region" {}
data "aws_caller_identity" "current_user" {}

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
      "arn:aws:rds-db:${data.aws_region.current_region.name}:${data.aws_caller_identity.current_user.account_id}:dbuser:${var.rds_resource_id}/${var.db_user_name}"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecr_managed" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy" "ec2_instance_role_policy" {
  name = "${var.project_name}RolePolicy"
  role = aws_iam_role.ec2_instance_role.id

  policy = data.aws_iam_policy_document.policy.json
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.project_name}InstanceProfile"
  role = aws_iam_role.ec2_instance_role.name
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "launch_template" {
  name_prefix   = "launch"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [
    var.ec2_security_group_id
  ]

  update_default_version = true

  user_data = base64encode(
    templatefile(
      "${path.module}/bin/user-data.tftpl",
      {
        env_vars = var.django_env
        # This file is what causes the changes that create a deployment.
        # Without an update on this file, launch config will not update, which won't cause a rolling upgrade.
        COMPOSE_FILE        = var.compose_file
        RDS_HOST            = var.rds_instance_address
        DOCKER_REGISTRY_URL = var.docker_registry_url
        AWS_S3_BUCKET_STATIC_NAME = var.s3_static_bucket_name
        AWS_S3_BUCKET_UPLOADS_NAME = var.s3_uploads_bucket_name
      }
    )
  )

  # TODO: Fix SSH key setup.
  # key_name = var.project_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  metadata_options {
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project_name}"
    }
  }
}

resource "aws_autoscaling_group" "asg" {
  desired_capacity    = 1
  max_size            = 2
  min_size            = 1
  vpc_zone_identifier = var.private_subnet_ids

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