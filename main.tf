data "aws_region" "current" {}
data "aws_caller_identity" "current_user" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.1"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs              = ["${data.aws_region.current.name}a", "${data.aws_region.current.name}b", "${data.aws_region.current.name}c"]
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
  project_name        = var.project_name
  private_cidr_blocks = module.vpc.private_subnets_cidr_blocks
}

module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
}

# Django uploads bucket
resource "aws_s3_bucket" "uploads" {
  bucket = join("-", compact([var.project_name, "uploads", var.bucket_name_postfix]))
}

# Django static bucket
resource "aws_s3_bucket" "static" {
  bucket = join("-", compact([var.project_name, "static", var.bucket_name_postfix]))
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
}

module "loadbalancer" {
  source = "./modules/loadbalancer"

  security_group_id  = module.sg.ld_sg_id
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

  django_env            = var.django_env
  compose_file          = var.compose_file
  target_group_arns     = module.loadbalancer.target_group_arns
  project_name          = var.project_name
  ec2_security_group_id = module.sg.ec2_sg_id
  s3_static_bucket_arn  = aws_s3_bucket.static.arn
  s3_uploads_bucket_arn = aws_s3_bucket.uploads.arn
  s3_static_bucket_name = aws_s3_bucket.static.bucket
  s3_uploads_bucket_name = aws_s3_bucket.uploads.bucket
  celery_queue_arn      = aws_sqs_queue.celery_queue.arn
  rds_resource_id       = module.rds.db_instance_resource_id
  rds_instance_address  = module.rds.db_instance_address
  db_user_name          = var.db_user_name
  docker_registry_url   = module.ecr.repository_url
  private_subnet_ids    = module.vpc.private_subnets
}

data "aws_acm_certificate" "domain_cert" {
  count = length(var.domain_name) > 0 ? 1 : 0
  provider = aws.useast1 # Search us-east-1 for the certificate

  domain      = var.domain_name
  statuses    = ["ISSUED"]
  most_recent = true
}

data "aws_cloudfront_origin_request_policy" "server" {
  name = "Managed-AllViewerAndCloudFrontHeaders-2022-06"
}

data "aws_cloudfront_cache_policy" "server" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "s3" {
  name = "Managed-CORS-S3Origin"
}

data "aws_cloudfront_cache_policy" "s3" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_response_headers_policy" "security" {
  name = "Managed-SecurityHeadersPolicy"
}

module "cdn" {
  source = "terraform-aws-modules/cloudfront/aws"
  version = "3.2.1"

  aliases = [var.domain_name]

  comment             = "${var.project_name} CDN"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"
  retain_on_delete    = false
  wait_for_deployment = false

  create_origin_access_control = true
  create_origin_access_identity = false

  origin_access_control = {
    s3_static = {
      description = "Access Static Files"
      origin_type = "s3",
      signing_behavior: "always",
      signing_protocol: "sigv4",
    },
    s3_upload = {
      description = "Access Uploaded Files",
      origin_type = "s3",
      signing_behavior: "always",
      signing_protocol: "sigv4",
    }
  }

  origin = {
    server = {
      domain_name = module.loadbalancer.url
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "match-viewer"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }

    s3_static = {
      domain_name = aws_s3_bucket.static.bucket_regional_domain_name
      origin_access_control = "s3_static"
    }

    s3_upload = {
      domain_name = aws_s3_bucket.uploads.bucket_regional_domain_name
      origin_access_control = "s3_upload"
    }
  }

  default_cache_behavior = {
    target_origin_id           = "server"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods   = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]

    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.server.id
    cache_policy_id = data.aws_cloudfront_cache_policy.server.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.security.id
    use_forwarded_values = false
  }

  ordered_cache_behavior = [
    {
      path_pattern           = "/static/*"
      target_origin_id       = "s3_static"
      viewer_protocol_policy = "redirect-to-https"

      origin_request_policy_id = data.aws_cloudfront_origin_request_policy.s3.id
      cache_policy_id = data.aws_cloudfront_cache_policy.s3.id
      response_headers_policy_id = data.aws_cloudfront_response_headers_policy.security.id
      use_forwarded_values = false
    },
    {
      path_pattern           = "/uploads/*"
      target_origin_id       = "s3_upload"
      viewer_protocol_policy = "redirect-to-https"

      origin_request_policy_id = data.aws_cloudfront_origin_request_policy.s3.id
      cache_policy_id = data.aws_cloudfront_cache_policy.s3.id
      response_headers_policy_id = data.aws_cloudfront_response_headers_policy.security.id
      use_forwarded_values = false
    },
  ]

  viewer_certificate = {
    acm_certificate_arn = data.aws_acm_certificate.domain_cert[0].arn
    ssl_support_method  = "sni-only"
  }
}

resource "aws_s3_bucket_policy" "oac_uploads" {
  bucket = aws_s3_bucket.uploads.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.uploads.arn}/*",
        Condition = {
          StringEquals = {
            "aws:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current_user.account_id}:distribution/${module.cdn.cloudfront_distribution_id}"
          }
        }
      },
    ],
  })
}

resource "aws_s3_bucket_policy" "oac_static" {
  bucket = aws_s3_bucket.static.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.static.arn}/*",
        Condition = {
          StringEquals = {
            "aws:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current_user.account_id}:distribution/${module.cdn.cloudfront_distribution_id}"
          }
        }
      },
    ],
  })
}
