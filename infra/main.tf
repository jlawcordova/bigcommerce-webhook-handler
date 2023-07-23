terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

module "bigcommerce-webhooks" {
  source = "../modules/bigcommerce-webhooks"
}