data "aws_region" "current" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.1"

  name = "${project_name}-vpc"
  cidr = var.vpc_cidr

  azs              = ["${aws_region.current.name}a", "${aws_region.current.name}b", "${aws_region.current.name}c"]
  private_subnets  = var.private_subnets
  database_subnets = var.database_subnets
  public_subnets   = var.public_subnets

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  enable_vpn_gateway     = false
}

module "sg" {
  source = "./modules/securitygroups"

  vpc_id              = module.vpc.vpc_id
  public_cidr_blocks  = module.vpc.public_subnets
  project_name        = var.project_name
  private_cidr_blocks = module.vpc.private_subnets
  target_port         = var.target_port
}

# Django uploads bucket
resource "aws_s3_bucket" "uploads" {
  bucket = "${var.bucket_name_prefix}_${var.project_name}_uploads"
}

# Django static bucket
resource "aws_s3_bucket" "static" {
  bucket = "${var.bucket_name_prefix}_${var.project_name}_static"
}

# Celery Queue (Default one, more can be created outside the module)
resource "aws_sqs_queue" "celery_queue" {
  name                      = "${var.project_name}-celery-queue"
  delay_seconds             = 10
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
}

module "rds" {
  source = "./modules/rds"

  db_sg_ids     = [module.sg.db_sg_id]
  db_subnet_ids = module.vpc.database_subnets
  project_name  = var.project_name
  vpc_id        = module.vpc.vpc_id
}

module "loadbalancer" {
  source = "./modules/loadbalancer"

  security_group_id  = module.sg.lb_sg_id
  project_name       = var.project_name
  domain_name        = var.domain_name
  subnet_ids         = module.vpc.public_subnets
  vpc_id             = module.vpc.vpc_id
  target_port        = var.target_port
  public_cidr_blocks = module.vpc.public_subnets
}

resource "aws_secretsmanager_secret" "project_secrets" {
  name = "${var.project_name}-secrets"
}

module "ec2" {
  source = "./modules/ec2"

  django_env             = var.django_env
  rds_port               = var.rds_port
  compose_file           = templatefile("${path.module}/docker-compose-release.yaml", { TAG = var.docker_tag })
  target_group_arns      = module.loadbalancer[0].target_group_arns
  project_name           = var.project_name
  target_port            = var.target_port
  vpc_id                 = module.vpc.vpc_id
  ec2_security_group_id  = module.sg.ec2_sg_id
  s3_static_bucket_arn   = aws_s3_bucket.static.arn
  s3_uploads_bucket_arn  = aws_s3_bucket.uploads.arn
  celery_queue_arn       = aws_sqs_queue.celery_queue.arn
}

# module "cdn" {
#   source = "terraform-aws-modules/cloudfront/aws"

#   # aliases = ["cdn.example.com"]

#   comment             = "${var.project_name} CDN"
#   enabled             = true
#   is_ipv6_enabled     = true
#   price_class         = "PriceClass_100"
#   retain_on_delete    = false
#   wait_for_deployment = false

#   create_origin_access_identity = true
#   origin_access_identities = {
#     s3_bucket_one = "My awesome CloudFront can access"
#   }

#   logging_config = {
#     bucket = "logs-my-cdn.s3.amazonaws.com"
#   }

#   origin = {
#     something = {
#       domain_name = "something.example.com"
#       custom_origin_config = {
#         http_port              = 80
#         https_port             = 443
#         origin_protocol_policy = "match-viewer"
#         origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
#       }
#     }

#     s3_one = {
#       domain_name = "my-s3-bycket.s3.amazonaws.com"
#       s3_origin_config = {
#         origin_access_identity = "s3_bucket_one"
#       }
#     }
#   }

#   default_cache_behavior = {
#     target_origin_id           = "something"
#     viewer_protocol_policy     = "allow-all"

#     allowed_methods = ["GET", "HEAD", "OPTIONS"]
#     cached_methods  = ["GET", "HEAD"]
#     compress        = true
#     query_string    = true
#   }

#   ordered_cache_behavior = [
#     {
#       path_pattern           = "/static/*"
#       target_origin_id       = "s3_one"
#       viewer_protocol_policy = "redirect-to-https"

#       allowed_methods = ["GET", "HEAD", "OPTIONS"]
#       cached_methods  = ["GET", "HEAD"]
#       compress        = true
#       query_string    = true
#     }
#   ]

#   viewer_certificate = {
#     acm_certificate_arn = "arn:aws:acm:us-east-1:135367859851:certificate/1032b155-22da-4ae0-9f69-e206f825458b"
#     ssl_support_method  = "sni-only"
#   }
# }