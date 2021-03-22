terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region     = "eu-west-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_s3_bucket" "moggiez_lambdas" {
  bucket = "moggiez-lambdas"
  acl    = "private"

  tags = {
    Project     = var.application
    Environment = "Prod"
  }
}