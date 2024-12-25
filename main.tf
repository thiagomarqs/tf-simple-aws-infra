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

module "network" {
  source = "./modules/network"
  region = var.region
}

module "compute" {
  source = "./modules/compute"
  region = var.region
  subnet_id = module.network.subnet_id
  vpc_security_group_ids = [ module.network.sg_id ]
}

resource "aws_s3_bucket" "bucket" {
  force_destroy = true
}
