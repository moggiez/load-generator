// Buses
resource "aws_cloudwatch_event_bus" "moggiez_load_test" {
  name = "moggiez-load-test"
}

// Scheduled events
// Domain Validator
resource "aws_cloudwatch_event_rule" "call_domain_validator" {
  name        = "moggies.io-call_domain_validator"
  description = "Call domain_validator_lambda on a schedule."

  schedule_expression = "cron(*/30 * * * ? *)"

  tags = {
    Project = var.application
  }
}

resource "aws_cloudwatch_event_target" "call_lambda_domain_validator" {
  rule      = aws_cloudwatch_event_rule.call_domain_validator.name
  target_id = "LambdaToTarget"
  arn       = module.domainValidator.lambda.arn
}