module "driver" {
  source    = "git@github.com:moggiez/terraform-modules.git//lambda_with_dynamo"
  name      = "driver_lambda"
  dist_dir  = var.dist_dir
  s3_bucket = aws_s3_bucket.moggiez_lambdas
  timeout   = 60
  policies = [
    aws_iam_policy.eventbridge_events.arn,
    aws_iam_policy.dynamodb_access_policy_loadtests.arn,
    aws_iam_policy.dynamodb_access_policy_playbooks.arn,
    aws_iam_policy.dynamodb_access_policy_organisations.arn
  ]
  layers = [
    data.aws_lambda_layer_version.db.arn,
    data.aws_lambda_layer_version.auth.arn,
    data.aws_lambda_layer_version.lambda_helpers.arn
  ]
}

module "worker" {
  source        = "git@github.com:moggiez/terraform-modules.git//event_driven_lambda"
  function_name = "MoggiezWorker"
  key           = "worker_lambda"
  s3_bucket     = aws_s3_bucket.moggiez_lambdas
  timeout       = 300
  dist_dir      = var.dist_dir
  policies      = []
}

module "archiver" {
  source        = "git@github.com:moggiez/terraform-modules.git//event_driven_lambda"
  function_name = "MoggiezArchiver"
  key           = "archiver_lambda"
  s3_bucket     = aws_s3_bucket.moggiez_lambdas
  dist_dir      = var.dist_dir
  policies      = [aws_iam_policy.s3_access.arn, aws_iam_policy.cloudwatch_metrics_access.arn]
}
