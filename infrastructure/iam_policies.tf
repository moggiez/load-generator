
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