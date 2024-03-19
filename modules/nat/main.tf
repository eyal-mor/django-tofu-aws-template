data "aws_ami" "nat" {
  most_recent = true
  owners      = ["568608671756"]

  filter {
    name   = "name"
    values = ["fck-nat-al2023-hvm-*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


module "fck-nat" {
  source = "git::https://github.com/RaJiska/terraform-aws-fck-nat.git"

  name                 = "${var.project_name}-nat-instance"
  vpc_id               = var.vpc_id
  subnet_id            = var.public_subnet_id
  ha_mode              = true  # Ensure a NAT instance is always available
  use_cloudwatch_agent = false # Disable Cloudwatch agent and have metrics reported
  use_spot_instances   = true  # Use spot instance for lowest costs
  ami_id               = data.aws_ami.nat.id
  ebs_root_volume_size = 8


  update_route_table = true
  route_tables_ids = {
    for idx, val in var.private_route_table_ids : "${idx}" => val
  }
}

resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = split("/", module.fck-nat.role_arn)[1]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
