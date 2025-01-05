terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      version = ">= 5.78.0"
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = local.default_tags
  }
}

# module "ec2_alb_asg" {
#   source = "./modules/ec2_alb_asg"
#   region = var.region
# }

# module "ec2_igw_roles" {
#   source = "./modules/ec2_igw_roles"
#   region = var.region
# }

# module "ec2_nlb" {
#   source = "./modules/ec2_nlb"
#   region = var.region
# }