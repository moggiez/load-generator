terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket         = "moggiez-terraform-state-backend"
    key            = "terraform.state"
    region         = "eu-west-1"
    dynamodb_table = "moggiez-terraform_state"
  }
}

provider "aws" {
  region     = var.region
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

resource "aws_s3_bucket_public_access_block" "bucket_block_public_access" {
  bucket = aws_s3_bucket.moggiez_lambdas.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# this doesn't work yet, don't know why
locals {
  tags = {
    Project = var.application
  }
}

resource "aws_cloudwatch_log_group" "moggiez_worker" {
  name = "/aws/events/moggiez_worker"
}

resource "aws_cloudwatch_log_group" "moggiez_driver" {
  name = "/aws/events/moggiez_driver"
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
module "worker_source_to_log_group" {
  source       = "./modules/eventrules/source_to_log_group"
  application  = var.application
  account      = var.account
  eventbus     = aws_cloudwatch_event_bus.moggiez_load_test
  event_source = "Worker"
  log_group    = aws_cloudwatch_log_group.moggiez_worker
}

module "driver_source_to_log_group" {
  source       = "./modules/eventrules/source_to_log_group"
  application  = var.application
  account      = var.account
  eventbus     = aws_cloudwatch_event_bus.moggiez_load_test
  event_source = "Driver"
  log_group    = aws_cloudwatch_log_group.moggiez_driver
}

module "rule_to_lambda" {
  source      = "./modules/eventrules/to_lambda"
  application = var.application
  account     = var.account
  region      = var.region
  eventbus    = aws_cloudwatch_event_bus.moggiez_load_test
  lambda      = module.worker.lambda
}