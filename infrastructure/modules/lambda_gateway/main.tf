resource "aws_api_gateway_rest_api" "moggiez" {
  name        = "MoggiezAPIGateway"
  description = "Moggiez API Gateway for triggering load tests"
}

resource "aws_api_gateway_resource" "proxy" {
   rest_api_id = aws_api_gateway_rest_api.moggiez.id
   parent_id   = aws_api_gateway_rest_api.moggiez.root_resource_id
   path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
   rest_api_id   = aws_api_gateway_rest_api.moggiez.id
   resource_id   = aws_api_gateway_resource.proxy.id
   http_method   = "POST"
   authorization = "NONE"
}

resource "aws_api_gateway_method" "proxy_root" {
   rest_api_id   = aws_api_gateway_rest_api.moggiez.id
   resource_id   = aws_api_gateway_rest_api.moggiez.root_resource_id
   http_method   = "POST"
   authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
   rest_api_id = aws_api_gateway_rest_api.moggiez.id
   resource_id = aws_api_gateway_method.proxy.resource_id
   http_method = aws_api_gateway_method.proxy.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = var.lambda.invoke_arn
}

resource "aws_api_gateway_integration" "lambda_root_integration" {
   rest_api_id = aws_api_gateway_rest_api.moggiez.id
   resource_id = aws_api_gateway_method.proxy_root.resource_id
   http_method = aws_api_gateway_method.proxy_root.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = var.lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "gateway_deployment" {
   depends_on = [
     aws_api_gateway_integration.lambda_integration,
     aws_api_gateway_integration.lambda_root_integration,
   ]

   rest_api_id = aws_api_gateway_rest_api.moggiez.id
   stage_name  = "prod"
}

# Allow API Gateway to Access Lambda
resource "aws_lambda_permission" "apigw" {
   statement_id  = "AllowAPIGatewayInvoke"
   action        = "lambda:InvokeFunction"
   function_name = var.lambda.function_name
   principal     = "apigateway.amazonaws.com"

   # The "/*/*" portion grants access from any method on any resource
   # within the API Gateway REST API.
   source_arn = "${aws_api_gateway_rest_api.moggiez.execution_arn}/*/*"
}
