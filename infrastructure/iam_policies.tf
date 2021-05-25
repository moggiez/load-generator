
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

resource "aws_iam_policy" "cloudwatch_metrics_access" {
  name        = "${var.application}-CloudWatchMetricsAccess"
  path        = "/"
  description = "IAM policy putting custom metrics in CloudWatch"

  policy = templatefile("templates/cloudwatch_metrics_access_policy.json", {})
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

resource "aws_iam_policy" "dynamodb_access_policy_loadtests" {
  name = "lambda_access_dynamodb_policy_loadtests"
  path = "/"

  policy = templatefile("templates/dynamo_access_policy.json", { table = "loadtests" })
}

resource "aws_iam_policy" "dynamodb_access_policy_playbooks" {
  name = "lambda_access_dynamodb_policy_playbooks"
  path = "/"

  policy = templatefile("templates/dynamo_access_policy.json", { table = "playbooks" })
}

resource "aws_iam_policy" "dynamodb_access_policy_organisations" {
  name = "lambda_access_dynamodb_policy_organisations"
  path = "/"

  policy = templatefile("templates/dynamo_access_policy.json", { table = "organisations" })
}