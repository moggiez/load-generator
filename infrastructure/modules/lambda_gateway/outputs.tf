output "base_url" {
  value = aws_api_gateway_deployment.gateway_deployment.invoke_url
}

output "api" {
  value = aws_api_gateway_rest_api.moggiez
}

output "api_resource" {
  value = aws_api_gateway_rest_api.moggiez.root_resource_id
}
