output "asg_arn" {
  description = "ARN of the bucket"
  value       = aws_autoscaling_group.asg.arn
}

output "asg_name" {
  description = "Name (id) of the bucket"
  value       = aws_autoscaling_group.asg.id
}

output "asg_version" {
  description = "Version of the ec2 asg"
  value       = aws_autoscaling_group.asg.launch_template
}
