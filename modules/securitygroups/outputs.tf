output "ld_sg_id" {
  description = "The security group id for load balancer"
  value       = aws_security_group.allow_ec2.id
}

output "ec2_sg_id" {
  description = "The security group id for ec2"
  value       = aws_security_group.allow_ec2.id
}

output "db_sg_id" {
  description = "The security group id for db"
  value       = aws_security_group.allow_db.id
}
