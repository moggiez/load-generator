resource "aws_api_gateway_resource" "_" {
  path_part   = var.resource_path_part
  parent_id   = var.api.root_resource_id
  rest_api_id = var.api.id
}

resource "aws_api_gateway_method" "_" {
  rest_api_id   = var.api.id
  resource_id   = aws_api_gateway_resource._.id
  http_method   = var.http_method
  authorization = var.authorizer != null ? "COGNITO_USER_POOLS" : "NONE"
  authorizer_id = var.authorizer != null ? var.authorizer.id : null
}

resource "aws_api_gateway_integration" "_" {
  rest_api_id             = var.api.id
  resource_id             = aws_api_gateway_resource._.id
  http_method             = aws_api_gateway_method._.http_method
  integration_http_method = "POST"

  type = "AWS_PROXY"
  uri  = var.lambda.invoke_arn
}