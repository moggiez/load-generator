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
  region = var.region
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

# Common policies
resource "aws_iam_policy" "s3_access" {
  name        = "${var.application}-S3Access"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:*"
        ],
        "Resource" : "arn:aws:s3:::*"
      }
    ]
  })
}

# Log groups
resource "aws_cloudwatch_log_group" "moggiez_worker" {
  name = "/aws/events/moggiez_worker"
}

resource "aws_cloudwatch_log_group" "moggiez_driver" {
  name = "/aws/events/moggiez_driver"
}

resource "aws_cloudwatch_log_group" "moggiez_archiver" {
  name = "/aws/events/moggiez_archiver"
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
  source        = "./modules/event_driven_lambda"
  function_name = "MoggiezWorker"
  key           = "worker_lambda"
  s3_bucket     = aws_s3_bucket.moggiez_lambdas
  dist_dir      = var.dist_dir
  dist_version  = var.dist_version
  policies      = []
}

module "archiver" {
  source        = "./modules/event_driven_lambda"
  function_name = "MoggiezArchiver"
  key           = "archiver_lambda"
  s3_bucket     = aws_s3_bucket.moggiez_lambdas
  dist_dir      = var.dist_dir
  dist_version  = var.dist_version
  policies      = [aws_iam_policy.s3_access.arn]
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

module "archiver_source_to_log_group" {
  source       = "./modules/eventrules/source_to_log_group"
  application  = var.application
  account      = var.account
  eventbus     = aws_cloudwatch_event_bus.moggiez_load_test
  event_source = "Archiver"
  log_group    = aws_cloudwatch_log_group.moggiez_archiver
}

module "user_call_event_to_lambda" {
  source       = "./modules/eventrules/detail_type_to_lambda"
  application  = var.application
  name         = "catch-type-to-lambda"
  account      = var.account
  region       = var.region
  detail_types = ["User Calls"]
  eventbus     = aws_cloudwatch_event_bus.moggiez_load_test
  lambda       = module.worker.lambda
}

module "worker_result_event_to_lambda" {
  source       = "./modules/eventrules/detail_type_to_lambda"
  application  = var.application
  name         = "catch-worker-results-to-lambda"
  account      = var.account
  region       = var.region
  detail_types = ["Worker Request Success", "Worker Request Failure"]
  eventbus     = aws_cloudwatch_event_bus.moggiez_load_test
  lambda       = module.archiver.lambda
}

module "gateway_to_driver_lambda" {
  source = "./modules/lambda_gateway"
  lambda = module.driver.lambda
}

# Results - integration from lambda to S3
## Success

resource "aws_s3_bucket" "moggiez_call_responses_success" {
  bucket = "moggiez-call-responses-success"
  acl    = "private"

  tags = {
    Project = var.application
  }
}

## Failure

resource "aws_s3_bucket" "moggiez_call_responses_failure" {
  bucket = "moggiez-call-responses-failure"
  acl    = "private"

  tags = {
    Project = var.application
  }
}