locals {
  stages = toset(["v1", "blue", "green"])
  stage  = "green"
}

resource "aws_api_gateway_rest_api" "_" {
  name        = "LoadtestAPI"
  description = "Loadtest API Gateway"
}

# LoadtestAPIs
module "gateway_to_driver_lambda" {
  source             = "./modules/lambda_gateway"
  http_method        = "POST"
  lambda             = module.driver.lambda
  resource_path_part = "loadtest"
  api                = aws_api_gateway_rest_api._
}

module "gateway_cors" {
  source          = "./modules/api_gateway_enable_cors"
  api_id          = aws_api_gateway_rest_api._.id
  api_resource_id = module.gateway_to_driver_lambda.api_resource.id
}

# Allow API Gateway to Access Lambda
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.driver.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api._.execution_arn}/*/*"
}

# Deployment of the API Gateway
resource "aws_api_gateway_deployment" "gateway_deployment" {
  for_each = local.stages

  depends_on = [
    module.gateway_to_driver_lambda.integration,
    module.gateway_cors.integration
  ]

  rest_api_id = aws_api_gateway_rest_api._.id
  description = each.value

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "loadtest_api_stage" {
  for_each = aws_api_gateway_deployment.gateway_deployment

  deployment_id = each.value.id
  rest_api_id   = aws_api_gateway_rest_api._.id
  stage_name    = each.value.description

  lifecycle {
    create_before_destroy = true
  }
}

module "playbook_api_subdomain_mapping" {
  source         = "./modules/api_subdomain_mapping"
  api            = aws_api_gateway_rest_api._
  api_stage_name = local.stage
  domain_name    = "moggies.io"
  api_subdomain  = "load-api"
}