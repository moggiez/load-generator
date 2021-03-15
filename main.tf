terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
   region = "eu-west-1"
   access_key = var.aws_access_key
   secret_key = var.aws_secret_key
}

resource "aws_s3_bucket" "moggiez_lambdas" {
    bucket = "moggiez-lambdas"
    acl    = "private"

    tags = {
        Project     = "Eventest"
        Name        = "eventest"
        Environment = "Prod"
    }
}

resource "aws_s3_bucket_object" "worker_lambda_s3_object" {
  bucket = aws_s3_bucket.moggiez_lambdas.id
  key    = "worker.lambda.${var.lambda_version}.zip"
  acl    = "private"
  source = "dist/worker.lambda.${var.lambda_version}.zip"
  etag = filemd5("dist/worker.lambda.${var.lambda_version}.zip")
}

resource "aws_s3_bucket_object" "driver_lambda_s3_object" {
  bucket = aws_s3_bucket.moggiez_lambdas.id
  key    = "driver.lambda.${var.lambda_version}.zip"
  acl    = "private"
  source = "dist/driver.lambda.${var.lambda_version}.zip"
  etag = filemd5("dist/driver.lambda.${var.lambda_version}.zip")
}

resource "aws_lambda_function" "moggiez_worker_fn" {
   function_name = "MoggiezWorker"
   s3_bucket = aws_s3_bucket.moggiez_lambdas.bucket
   s3_key = aws_s3_bucket_object.worker_lambda_s3_object.key

   handler = "worker.handler"
   runtime = "nodejs14.x"

   role = aws_iam_role.lambda_exec.arn
}

resource "aws_lambda_function" "moggiez_driver_fn" {
   function_name = "MoggiezDriver"
   s3_bucket = aws_s3_bucket.moggiez_lambdas.bucket
   s3_key = aws_s3_bucket_object.driver_lambda_s3_object.key

   handler = "driver.handler"
   runtime = "nodejs14.x"

   role = aws_iam_role.lambda_exec.arn
}

resource "aws_iam_policy" "eventbridge_events" {
  name        = "eventbridge_access"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "events:PutEvents",
        "Resource": "*"
      }
    ]
  })
}

 # IAM role which dictates what other AWS services the Lambda function
 # may access.
resource "aws_iam_role" "lambda_exec" {
  name = "moggiez_lambda_execution_role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  })
  managed_policy_arns = [aws_iam_policy.eventbridge_events.arn]
}