data "aws_acm_certificate" "domain_cert" {
  domain      = var.domain_name
  statuses    = ["ISSUED"]
  most_recent = true
}

resource "aws_lb" "loadbalancer" {
  name               = "${var.project_name}-loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [
    aws_security_group.allow_lb.id
  ]
  subnets            = var.subnet_ids


  enable_deletion_protection = false
}

resource "aws_lb_target_group" "tg" {
  name     = "${var.project_name}-target-group"
  port     = var.target_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    path                = "/health-check/"
    port                = 8000
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 10
  }
}


resource "aws_lb_listener" "forward_tls" {
  load_balancer_arn = aws_lb.loadbalancer.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.domain_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

}

resource "aws_lb_listener" "forward_redirect" {
  load_balancer_arn = aws_lb.loadbalancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_security_group" "allow_lb" {
  name        = "${var.project_name}-allow_lb"
  description = "Allows inbound from public network"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [
      var.ec2_security_group_id
    ]
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
