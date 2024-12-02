output "target_group_arns" {
  description = "ARN of the AWS Load Balancer"
  value       = [aws_lb_target_group.tg.arn]
}

output "url" {
  description = "URL of the AWS Load Balancer"
  value       = aws_lb.loadbalancer.dns_name
}

output "alarm_sns_topic_arn" {
  description = "ARN of the SNS topic for 5xx alarms"
  value       = aws_sns_topic.alerts_5xx.arn
}
