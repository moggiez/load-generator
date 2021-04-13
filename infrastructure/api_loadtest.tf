# LoadtestAPIs
module "gateway_to_driver_lambda" {
  source             = "./modules/lambda_gateway"
  name               = "LoadtestAPI"
  http_method        = "POST"
  lambda             = module.driver.lambda
  resource_path_part = "loadtest"
}

module "gateway_cors" {
  source          = "./modules/api_gateway_enable_cors"
  api_id          = module.gateway_to_driver_lambda.api.id
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
  source_arn = "${module.gateway_to_driver_lambda.api.execution_arn}/*/*"
}

# Deployment of the API Gateway
resource "aws_api_gateway_deployment" "gateway_deployment" {
  depends_on = [
    module.gateway_to_driver_lambda.integration,
    module.gateway_cors.integration
  ]

  rest_api_id = module.gateway_to_driver_lambda.api.id
  stage_name  = "v1"
}