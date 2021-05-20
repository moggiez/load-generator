resource "aws_s3_bucket" "moggiez_lambdas" {
  bucket = "moggies.io-lambdas"
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