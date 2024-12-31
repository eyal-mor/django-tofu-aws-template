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

output "docker_repository_url" {
  description = "The URL of the docker registry"
  value       = module.ecr.repository_url
}

output "cloudfront_domain_name" {
  description = "The domain name of the cloudfront distribution"
  value       = module.cdn.cloudfront_distribution_domain_name
}

output "cloudfront_id" {
  description = "The domain name of the cloudfront distribution"
  value       = module.cdn.cloudfront_distribution_id
}


output "private_route_table_ids" {
  value = module.vpc.private_route_table_ids
}
output "private_subnets_cidr_blocks" {
  value = module.vpc.private_subnets_cidr_blocks
}
output "private_subnets" {
  value = module.vpc.private_subnets
}
output "db_sg_id" {
  value = module.sg.db_sg_id
}
output "database_subnets" {
  value = module.vpc.database_subnets
}
output "ld_sg_id" {
  value = module.sg.ld_sg_id
}
output "public_subnets" {
  value = module.vpc.public_subnets
}
output "target_group_arns" {
  value = module.loadbalancer.target_group_arns
}
output "ec2_sg_id" {
  value = module.sg.ec2_sg_id
}
output "db_instance_resource_id" {
  value = module.rds.db_instance_resource_id
}
output "url" {
  value = module.loadbalancer.url
}

output "aws_sns_topic_subscription_arn" {
  value = length(aws_sns_topic_subscription.sns-topic) > 0 ? aws_sns_topic_subscription.sns-topic[0].arn : ""
}