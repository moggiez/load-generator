// Scheduled events
resource "aws_cloudwatch_event_rule" "call_metrics_saver" {
  name        = "moggies.io-call_metrics_saver"
  description = "Call metrics_saver_lambda on a schedule."

  schedule_expression = "cron(*/30 * * * ? *)"

  tags = {
    Project = var.application
  }
}

resource "aws_cloudwatch_event_target" "call_lambda_metrics_saver" {
  rule      = aws_cloudwatch_event_rule.call_metrics_saver.name
  target_id = "LambdaToTarget"
  arn       = module.metricsSaver.lambda.arn
}

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