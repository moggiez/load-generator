module "worker" {
  source        = "git@github.com:moggiez/terraform-modules.git//event_driven_lambda"
  function_name = "worker_lambda"
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
  policies = [
    aws_iam_policy.s3_access.arn,
    aws_iam_policy.cloudwatch_metrics_access.arn
  ]
}

module "metricsSaver" {
  source      = "git@github.com:moggiez/terraform-modules.git//lambda_with_dynamo"
  name        = "metrics_saver_lambda"
  dist_dir    = var.dist_dir
  s3_bucket   = aws_s3_bucket.moggiez_lambdas
  environment = local.environment

  timeout = 60

  policies = [
    aws_iam_policy.s3_access.arn,
    aws_iam_policy.cloudwatch_metrics_access.arn,
    aws_iam_policy.dynamodb_access_policy_loadtests.arn,
    aws_iam_policy.dynamodb_access_policy_loadtest_metrics.arn
  ]

  layers = []
}

module "domainValidator" {
  source      = "git@github.com:moggiez/terraform-modules.git//lambda_with_dynamo"
  name        = "domain_validator_lambda"
  dist_dir    = var.dist_dir
  s3_bucket   = aws_s3_bucket.moggiez_lambdas
  environment = local.environment

  timeout = 60

  policies = [
    aws_iam_policy.dynamodb_access_policy_domains.arn,
  ]

  layers = []
}