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


resource "random_pet" "project" {
  length = 2
}

module "bigcommerce-webhooks" {
  source = "./modules/bigcommerce-webhooks"

  # Use a random name when the project variable is not set.
  project = coalesce(var.project, "bigcommerce-webhook-${random_pet.project.id}")
  environment = var.environment
}