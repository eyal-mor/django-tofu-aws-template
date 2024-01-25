output "asg_arn" {
  description = "ARN of the bucket"
  value       = aws_autoscaling_group.asg.arn
}
