resource "aws_cloudwatch_event_bus" "moggiez_load_test" {
  name = "moggiez-load-test"

  tags = {
    Project     = var.application
    Environment = "Prod"
  }
}

# Rule - Target: catch all and call driver lambda
resource "aws_cloudwatch_event_rule" "catch_all_lambda" {
  event_bus_name = aws_cloudwatch_event_bus.moggiez_load_test.name
  name           = "moggiez-load-test-catch-all"
  description    = "Catch all events on load-test event bus"

  event_pattern = <<EOF
{
  "account": ["${var.account}"],
  "detail-type": ["User Calls", "Call Result"]
}
EOF

  tags = {
    Project     = var.application
    Environment = "Prod"
  }
}

resource "aws_cloudwatch_event_target" "call_lambda" {
  event_bus_name = aws_cloudwatch_event_bus.moggiez_load_test.name
  rule           = aws_cloudwatch_event_rule.catch_all_lambda.name
  target_id      = "MoggiezDriver"
  arn            = aws_lambda_function.moggiez_worker_fn.arn
}


# Rule - Target: catch all and log to CloudWatch log group /aws/events/moggiez_test 
resource "aws_cloudwatch_log_group" "moggiez_test" {
  name = "/aws/events/moggiez_test"
}

resource "aws_cloudwatch_event_rule" "catch_all_log" {
  event_bus_name = aws_cloudwatch_event_bus.moggiez_load_test.name
  name           = "moggiez-load-test-catch-all-log"
  description    = "Catch all events on load-test event bus and log to CloudWatch Logs"

  event_pattern = <<EOF
{
  "account": ["${var.account}"],
  "detail-type": ["User Calls", "Call Result"]
}
EOF

  tags = {
    Project     = var.application
    Environment = "Prod"
  }
}

resource "aws_cloudwatch_event_target" "catch_all_log" {
  event_bus_name = aws_cloudwatch_event_bus.moggiez_load_test.name
  rule           = aws_cloudwatch_event_rule.catch_all_log.name
  target_id      = "MoggiezTestLogs"
  arn            = aws_cloudwatch_log_group.moggiez_test.arn
}
