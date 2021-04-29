
resource "aws_s3_bucket_object" "lambda_s3_object" {
  bucket = var.s3_bucket.id
  key    = "${var.key}.${var.dist_version}.zip"
  acl    = "private"
  source = "${var.dist_dir}/${var.key}.${var.dist_version}.zip"
  etag   = filemd5("${var.dist_dir}/${var.key}.${var.dist_version}.zip")
}

resource "aws_lambda_function" "moggiez_worker_fn" {
  function_name = var.function_name
  s3_bucket     = var.s3_bucket.bucket
  s3_key        = aws_s3_bucket_object.lambda_s3_object.key
  timeout       = var.timeout

  handler          = "index.handler"
  runtime          = "nodejs14.x"
  source_code_hash = filebase64sha256("${var.dist_dir}/${var.key}.${var.dist_version}.zip")

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_iam_policy" "eventbridge_events" {
  name        = "eventbridge_access_${var.key}"
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

resource "aws_iam_role" "lambda_exec" {
  name = "moggiez_${var.key}_execution_role"
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
  managed_policy_arns = concat(var.policies, [aws_iam_policy.eventbridge_events.arn])
}