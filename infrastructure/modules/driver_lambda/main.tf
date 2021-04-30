resource "aws_s3_bucket_object" "driver_lambda_s3_object" {
  bucket = var.s3_bucket.id
  key    = "driver_lambda.${var.dist_version}.zip"
  acl    = "private"
  source = "${var.dist_dir}/driver_lambda.${var.dist_version}.zip"
  etag   = filemd5("${var.dist_dir}/driver_lambda.${var.dist_version}.zip")
}

resource "aws_lambda_function" "moggiez_driver_fn" {
  function_name = "MoggiezDriver"
  s3_bucket     = var.s3_bucket.bucket
  s3_key        = aws_s3_bucket_object.driver_lambda_s3_object.key
  timeout       = var.timeout

  handler          = "index.handler"
  runtime          = "nodejs14.x"
  source_code_hash = filebase64sha256("${var.dist_dir}/driver_lambda.${var.dist_version}.zip")

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_iam_policy" "eventbridge_events" {
  name        = "eventbridge_access_driver"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "events:PutEvents",
        "Resource" : "*"
      }
    ]
  })
}


# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "lambda_exec" {
  name = "moggiez_driver_lambda_execution_role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
      }
    ]
  })
  managed_policy_arns = [aws_iam_policy.eventbridge_events.arn]
}