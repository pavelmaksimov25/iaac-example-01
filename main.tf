data "aws_ami" "example_ami" {
    most_recent = true

    owners = [var.environment.ami_filter.owner]

    filter {
      name   = "name"
      values = [var.environment.ami_filter.name]
    }

    filter {
      name   = "virtualization-type"
      values = ["hvm"]
    }
}

module "example_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.environment.name
  cidr = "${var.environment.network_prefix}.0.0/16"

  azs             = ["eu-north-1a","eu-north-1b","eu-north-1c"]
  public_subnets  = ["${var.environment.network_prefix}.101.0/24", "${var.environment.network_prefix}.102.0/24", "${var.environment.network_prefix}.103.0/24"]

  tags = {
    Terraform   = "true"
    Environment = var.environment.name
  }
}

module "example_autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "6.5.2"

  name = "${var.environment.name}-example"

  min_size            = var.asg_min
  max_size            = var.asg_max
  vpc_zone_identifier = module.example_vpc.public_subnets
  target_group_arns   = module.example_alb.target_group_arns
  security_groups     = [module.example_sg.security_group_id]
  instance_type       = var.instance_type
  image_id            = data.aws_ami.app_ami.id
}

module "example_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name = "${var.environment.name}-example-alb"

  load_balancer_type = "application"

  vpc_id             = module.example_vpc.vpc_id
  subnets            = module.example_vpc.public_subnets
  security_groups    = [module.example_sg.security_group_id]

  target_groups = [
    {
      name_prefix      = "${var.environment.name}-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = var.environment.name
  }
}

module "example_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.13.0"

  vpc_id  = module.example_vpc.vpc_id
  name    = "${var.environment.name}-example"
  ingress_rules = ["https-443-tcp","http-80-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}