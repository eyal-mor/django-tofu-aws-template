output "target_group_arns" {
  description = "ARN of the AWS Load Balancer"
  value       = [aws_lb_target_group.tg.arn]
}
