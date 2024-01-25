data "aws_region" "current" {}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${project_name}-vpc"
  cidr = "10.0.0.0/16"

  azs              = ["${aws_region.current.name}a", "${aws_region.current.name}b", "${aws_region.current.name}c"]
  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  database_subnets = ["10.0.201.0/26", "10.0.201.64/26", "10.0.201.128/26"]
  public_subnets   = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]


  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  enable_vpn_gateway     = false
}

module "sg" {
  source ="./modules/securitygroups"

  vpc_id = module.vpc.vpc_id
  public_cidr_blocks = module.vpc.public_subnets
  project_name = var.project_name
  private_cidr_blocks = module.vpc.private_subnets
  target_port = var.target_port
}

# Django uploads bucket
resource "aws_s3_bucket" "uploads" {
  bucket = "${var.bucket_name_prefix}_uploads"
}

# Django static bucket
resource "aws_s3_bucket" "static" {
  bucket = "${var.bucket_name_prefix}_static"
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

  security_group_id = module.sg.lb_sg_id
  project_name      = var.project_name
  domain_name       = var.domain_name
  subnet_ids        = module.vpc.public_subnets
  vpc_id = module.vpc.vpc_id
  target_port = var.target_port
  public_cidr_blocks =  module.vpc.public_subnets
}

module "ec2" {
  source = "./modules/ec2"

  database_name                      = var.database_name
  django_settings_module             = var.django_settings_module
  django_env                         = var.django_env
  rds_port                           = var.rds_port
  secrets_manager_rds_path           = var.secrets_manager_rds_path
  secrets_manager_django_secret_path = var.secrets_manager_django_secret_path
  compose_file                       = templatefile("${path.module}/docker-compose-release.yaml", { TAG = var.docker_tag })
  target_group_arns                  = module.loadbalancer[0].target_group_arns
  project_name                       = var.project_name
  target_port = var.target_port
  vpc_id = module.vpc.vpc_id
  ec2_security_group_id = module.sg.ec2_sg_id
  s3_static_bucket_arn = aws_s3_bucket.static.arn
  s3_uploads_bucket_arn = aws_s3_bucket.uploads.arn
  celery_queue_arn = aws_sqs_queue.celery_queue.arn
}

