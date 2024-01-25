resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.bucket_name
  tags   = var.tags
}

resource "aws_sqs_queue" "celery_queue" {
  name                      = var.celery_queue_name
  delay_seconds             = 10
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
}

module "loadbalancer" {
  source            = "./loadbalancer"
  count  = var.local ? 0 : 1

  security_group_id = var.security_group_id
  project_name      = var.project_name
  domain_name       = var.domain_name
}

module "ec2" {
  source = "./ec2"
  count  = var.local ? 0 : 1

  database_name                      = var.database_name
  django_settings_module             = var.django_settings_module
  django_env                         = var.django_env
  rds_port                           = var.rds_port
  secrets_manager_rds_path           = var.secrets_manager_rds_path
  secrets_manager_django_secret_path = var.secrets_manager_django_secret_path
  compose_file                       = templatefile("${path.module}/docker-compose-release.yaml", { TAG = var.docker_tag })
  target_group_arns                  = module.loadbalancer[0].target_group_arns
  project_name                       = var.project_name
}
