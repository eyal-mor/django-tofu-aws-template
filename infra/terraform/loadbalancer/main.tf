data "aws_acm_certificate" "Project-api" {
  domain      = "api.Project.io"
  statuses    = ["ISSUED"]
  most_recent = true
}

resource "aws_lb" "Project" {
  name               = "Project"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-09b1b44be29e16d93"]
  subnets            = ["subnet-0f6eb80d10f7730ba", "subnet-00280766c2869476f"]


  enable_deletion_protection = false
}

resource "aws_lb_target_group" "Project" {
  name     = "Project"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = "vpc-0f63f41b8f4295c58"

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
  load_balancer_arn = aws_lb.Project.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.Project-api.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Project.arn
  }

}

resource "aws_lb_listener" "forward_redirect" {
  load_balancer_arn = aws_lb.Project.arn
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

