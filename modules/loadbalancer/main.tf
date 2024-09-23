data "aws_acm_certificate" "domain_cert" {
  count = length(var.domain_name) > 0 ? 1 : 0

  domain      = var.domain_name
  statuses    = ["ISSUED"]
  most_recent = true
}

resource "aws_lb" "loadbalancer" {
  name               = "${var.project_name}-loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups = [
    var.security_group_id
  ]

  subnets                    = var.subnet_ids
  enable_deletion_protection = false
  preserve_host_header = true
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

  # Wait 5 minutes before deregistering the target
  deregistration_delay = 300

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_lb_listener" "forward_tls" {
  count = length(var.domain_name) > 0 ? 1 : 0

  load_balancer_arn = aws_lb.loadbalancer.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.domain_cert[0].arn

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
