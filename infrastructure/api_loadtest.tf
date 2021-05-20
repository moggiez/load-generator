locals {
  stages = toset(["blue", "green"])
  stage  = "blue"
}

resource "aws_api_gateway_rest_api" "_" {
  name        = "RunLoadtestAPI"
  description = "Run Loadtest API Gateway"
}

resource "aws_api_gateway_authorizer" "_" {
  name          = "MoggiesUserAuthorizer"
  rest_api_id   = aws_api_gateway_rest_api._.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = ["arn:aws:cognito-idp:${var.region}:${var.account}:userpool/${var.user_pool_id}"]
}

# LoadtestAPIs
locals {
  http_methods = toset(["POST"])
}

module "gateway_to_driver_lambda" {
  source             = "github.com/moggiez/terraform-modules/lambda_gateway"
  http_methods       = local.http_methods
  lambda             = module.driver.lambda
  resource_path_part = "run"
  api                = aws_api_gateway_rest_api._
  authorizer         = aws_api_gateway_authorizer._
}

module "gateway_cors" {
  source          = "github.com/moggiez/terraform-modules/api_gateway_enable_cors"
  api_id          = aws_api_gateway_rest_api._.id
  api_resource_id = module.gateway_to_driver_lambda.api_resource.id
}

# Allow API Gateway to Access Lambda
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.driver.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api._.execution_arn}/*/*"
}

module "driver_lambda_api_proxy" {
  source              = "github.com/moggiez/terraform-modules/api_resource_proxy"
  api                 = aws_api_gateway_rest_api._
  http_methods        = local.http_methods
  parent_api_resource = module.gateway_to_driver_lambda.api_resource
  lambda              = module.driver.lambda
  authorizer          = aws_api_gateway_authorizer._
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

  triggers = {
    redeployment = sha1("${timestamp()}")
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
  source         = "github.com/moggiez/terraform-modules/api_subdomain_mapping"
  api            = aws_api_gateway_rest_api._
  api_stage_name = local.stage
  domain_name    = "moggies.io"
  api_subdomain  = "load-api"
}