terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.46"
    }
  }
  backend "s3" {
    bucket       = "blackofi-terraform-storage"
    key          = "dev.tfstate"
    region       = "us-east-2"
    use_lockfile = true
  }
  required_version = ">= v1.15.4"
}

provider "aws" {
  region = var.region
}

module "network" {
  source   = "../../modules/network"
  name     = var.name
  vpc_cidr = var.vpc_cidr
  az_count = var.az_count
}

module "compute" {
  source                = "../../modules/compute"
  name                  = var.name
  vpc_id                = module.network.vpc_id
  public_subnet_id      = module.network.public_subnets[0]
  target_group_arn      = module.network.target_group_arn
  alb_security_group_id = module.network.alb_security_group_id
  instance_type         = var.instance_type
  asg_min_size          = var.asg_min_size
  asg_max_size          = var.asg_max_size
  asg_desired_capacity  = var.asg_desired_capacity
}

output "alb_dns" {
  value       = module.network.alb_dns_name
  description = "DNS name of the Application Load Balancer"
}

output "asg_name" {
  value       = module.compute.asg_name
  description = "Name of the Auto Scaling Group managing EC2 instances"
}

output "asg_arn" {
  value       = module.compute.asg_arn
  description = "ARN of the Auto Scaling Group"
}
