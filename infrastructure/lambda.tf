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