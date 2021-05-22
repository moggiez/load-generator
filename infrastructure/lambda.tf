module "driver" {
  source       = "git@github.com:moggiez/terraform-modules.git//driver_lambda"
  s3_bucket    = aws_s3_bucket.moggiez_lambdas
  timeout      = 60
  dist_dir     = var.dist_dir
  dist_version = var.dist_version
}

module "worker" {
  source        = "git@github.com:moggiez/terraform-modules.git//event_driven_lambda"
  function_name = "MoggiezWorker"
  key           = "worker_lambda"
  s3_bucket     = aws_s3_bucket.moggiez_lambdas
  timeout       = 300
  dist_dir      = var.dist_dir
  dist_version  = var.dist_version
  policies      = []
}

module "archiver" {
  source        = "git@github.com:moggiez/terraform-modules.git//event_driven_lambda"
  function_name = "MoggiezArchiver"
  key           = "archiver_lambda"
  s3_bucket     = aws_s3_bucket.moggiez_lambdas
  dist_dir      = var.dist_dir
  dist_version  = var.dist_version
  policies      = [aws_iam_policy.s3_access.arn, aws_iam_policy.cloudwatch_metrics_access.arn]
}
