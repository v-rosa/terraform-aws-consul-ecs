provider "aws" {
  region = var.region
}

locals {
  name = "consul-ecs-perf"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.78.0"

  name                 = local.name
  cidr                 = "172.16.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["172.16.224.0/19"]
  public_subnets       = ["172.16.192.0/19", "172.16.160.0/19", "172.16.128.0/19", "172.16.0.0/17"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  tags                 = var.tags
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = local.name
  tags = var.tags
}
