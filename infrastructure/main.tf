terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket         = "moggies.io-terraform-state-backend"
    key            = "load-generator-terraform.state"
    region         = "eu-west-1"
    dynamodb_table = "moggies.io-terraform_state"
  }
}

provider "aws" {
  region = var.region
}


# this doesn't work yet, don't know why
locals {
  tags = {
    Project = var.application
  }
}