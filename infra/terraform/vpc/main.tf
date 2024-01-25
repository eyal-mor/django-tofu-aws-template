data "aws_region" "current" {}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${project_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${aws_region.current.name}a", "${aws_region.current.name}b", "${aws_region.current.name}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  database_subnets = ["10.0.201.0/26", "10.0.201.64/26", "10.0.201.128/26"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]


  enable_nat_gateway = true
  single_nat_gateway = true
  one_nat_gateway_per_az = false
  enable_vpn_gateway = false
}