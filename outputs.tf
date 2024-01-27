output "s3_static_bucket_arn" {
  description = "ARN of the bucket"
  value       = aws_s3_bucket.static.arn
}

output "s3_static_bucket_name" {
  description = "Name (id) of the bucket"
  value       = aws_s3_bucket.static.id
}

output "s3_uploads_bucket_arn" {
  description = "ARN of the bucket"
  value       = aws_s3_bucket.uploads.arn
}


output "s3_uploads_bucket_name" {
  description = "Name (id) of the bucket"
  value       = aws_s3_bucket.uploads.id
}

output "ec2_asg_version" {
  description = "Version of the ec2 asg"
  value       = module.ec2.asg_version
}

output "rds_db_instance_address" {
  description = "The address of the RDS instance"
  value       = module.rds.db_instance_address
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "celery_queue_arn" {
  description = "The ARN of the SQS queue"
  value       = aws_sqs_queue.celery_queue.arn
}
