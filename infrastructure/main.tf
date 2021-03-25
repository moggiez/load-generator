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
    Project = var.application
  }
}

# this doesn't work yet, don't know why
locals {
  tags = {
    Project = var.application
  }
}

resource "aws_cloudwatch_log_group" "moggiez_test" {
  name = "/aws/events/moggiez_test"
}

resource "aws_cloudwatch_event_bus" "moggiez_load_test" {
  name = "moggiez-load-test"
}

module "driver" {
  source       = "./modules/driver_lambda"
  s3_bucket    = aws_s3_bucket.moggiez_lambdas
  dist_dir     = var.dist_dir
  dist_version = var.dist_version
}

module "worker" {
  source       = "./modules/worker_lambda"
  s3_bucket    = aws_s3_bucket.moggiez_lambdas
  dist_dir     = var.dist_dir
  dist_version = var.dist_version
}

# Creates event rules to link together events and lambdas
module "rule_to_log_group" {
  source      = "./modules/eventrules/to_log_group"
  application = var.application
  account     = var.account
  eventbus    = aws_cloudwatch_event_bus.moggiez_load_test
  log_group   = aws_cloudwatch_log_group.moggiez_test
}

module "rule_to_lambda" {
  source      = "./modules/eventrules/to_lambda"
  application = var.application
  account     = var.account
  region      = var.region
  eventbus    = aws_cloudwatch_event_bus.moggiez_load_test
  lambda      = module.worker.lambda
}