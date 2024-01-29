

/*
  This Terraform code defines three AWS security groups: allow_lb, ec2_in, and allow_db.
  - The allow_lb security group allows inbound traffic on ports 443 and 80 from the public network.
  - The ec2_in security group allows inbound traffic on port 443 from the allow_lb security group.
  - The allow_db security group allows inbound traffic on port 5432 from the ec2_in security group, restricted to the private network.
  All security groups have egress rules that allow all outbound traffic.
*/

resource "aws_security_group" "allow_lb" {
  name        = "${var.project_name}-allow_lb"
  description = "Allows inbound from public network"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.public_cidr_blocks
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.public_cidr_blocks
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

resource "aws_security_group" "allow_ec2" {
  name        = "${var.project_name}-ec2_in"
  description = "Allows inbound from public network"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 443
    to_port   = 65535
    protocol  = "tcp"
    security_groups = [
      aws_security_group.allow_lb.id
    ]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

resource "aws_security_group" "allow_db" {
  name        = "${var.project_name}-allow_db"
  description = "Allows inbound from private network"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    security_groups = [
      aws_security_group.allow_ec2.id
    ]
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
