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

resource "aws_s3_bucket" "eventest_lambdas" {
    bucket = "eventest-lambdas"
    acl    = "private"

    tags = {
        Project     = "Eventest"
        Name        = "eventest"
        Environment = "Prod"
    }
}

resource "aws_s3_bucket_object" "caller_lambda_s3_object" {
  bucket = aws_s3_bucket.eventest_lambdas.id
  key    = "caller.lambda.${var.lambda_version}.zip"
  acl    = "private"
  source = "dist/caller.lambda.${var.lambda_version}.zip"
  etag = filemd5("dist/caller.lambda.${var.lambda_version}.zip")
}

resource "aws_lambda_function" "eventest_caller_lambda" {
   function_name = "EventestCaller"
   s3_bucket = aws_s3_bucket.eventest_lambdas.bucket
   s3_key = aws_s3_bucket_object.caller_lambda_s3_object.key

   handler = "main.handler"
   runtime = "nodejs14.x"

   role = aws_iam_role.lambda_exec.arn
}

 # IAM role which dictates what other AWS services the Lambda function
 # may access.
resource "aws_iam_role" "lambda_exec" {
   name = "eventest_caller_lambda"

   assume_role_policy = <<EOF
{
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
}
EOF

}