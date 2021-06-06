data "aws_lambda_layer_version" "db" {
  layer_name = "moggies_layer_db"
}

data "aws_lambda_layer_version" "auth" {
  layer_name = "moggies_layer_auth"
}

data "aws_lambda_layer_version" "lambda_helpers" {
  layer_name = "moggies_layer_lambda_helpers"
}

data "aws_lambda_layer_version" "metrics" {
  layer_name = "moggies_layer_metrics"
}