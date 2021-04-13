# PLAYBOOK API
resource "aws_iam_policy" "dynamodb_playbook_api" {
  name = "playbook_api_lambda_access_dynamodb_policy"
  path = "/"

  policy = templatefile("templates/dynamo_access_policy.json", { table = "playbooks" })
}

module "playbook_api_lambda" {
  source         = "./modules/api_lambda"
  s3_bucket      = aws_s3_bucket.moggiez_lambdas
  dist_dir       = var.dist_dir
  dist_version   = var.dist_version
  name           = "playbook_api"
  dynamodb_table = "playbooks"
  policies       = [aws_iam_policy.dynamodb_playbook_api.arn]
}

module "gateway_to_playbook_api_lambda" {
  source             = "./modules/lambda_gateway"
  name               = "PlaybookAPI"
  lambda             = module.playbook_api_lambda.lambda
  http_method        = "GET"
  resource_path_part = "playbook"
}

module "playbook_api_cors" {
  source          = "./modules/api_gateway_enable_cors"
  api_id          = module.gateway_to_playbook_api_lambda.api.id
  api_resource_id = module.gateway_to_playbook_api_lambda.api_resource.id
}

resource "aws_lambda_permission" "_" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.playbook_api_lambda.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${module.gateway_to_playbook_api_lambda.api.execution_arn}/*/*"
}

# Deployment of the API Gateway
resource "aws_api_gateway_deployment" "playbook_api_deployment" {
  depends_on = [
    module.gateway_to_playbook_api_lambda.integration,
    module.playbook_api_cors.integration
  ]

  rest_api_id = module.gateway_to_playbook_api_lambda.api.id
  stage_name  = "v1"
}
# END PLAYBOOK API