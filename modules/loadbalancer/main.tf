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

resource "aws_sns_topic" "alerts_5xx" {
  name = "5xxAlerts"
}

resource "aws_cloudwatch_metric_alarm" "alert_5xx_target" {
  alarm_name          = "${var.project_name}-5xxErrorTargetCount"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300 # 5 minutes
  statistic           = "Sum"
  threshold           = var.threshold_5xx
  alarm_description   = "Number of healthy nodes in Target Group"
  actions_enabled     = "true"
  alarm_actions       = [aws_sns_topic.alerts_5xx.arn]
  ok_actions          = [aws_sns_topic.alerts_5xx.arn]
  dimensions = {
    TargetGroup  = aws_lb_target_group.tg.arn_suffix
    LoadBalancer = aws_lb.loadbalancer.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "alert_5xx" {
  alarm_name          = "${var.project_name}-5xxErrorCount"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300 # 5 minutes
  statistic           = "Sum"
  threshold           = var.threshold_5xx
  alarm_description   = "Number of healthy nodes in Target Group"
  actions_enabled     = "true"
  alarm_actions       = [aws_sns_topic.alerts_5xx.arn]
  ok_actions          = [aws_sns_topic.alerts_5xx.arn]
  dimensions = {
    TargetGroup  = aws_lb_target_group.tg.arn_suffix
    LoadBalancer = aws_lb.loadbalancer.arn_suffix
  }
}
