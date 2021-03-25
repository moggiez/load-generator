resource "aws_cloudwatch_event_rule" "catch_all_log" {
  event_bus_name = var.eventbus.name
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
  }
}

resource "aws_cloudwatch_event_target" "catch_all_log" {
  event_bus_name = var.eventbus.name
  rule           = aws_cloudwatch_event_rule.catch_all_log.name
  target_id      = "MoggiezTestLogs"
  arn            = var.log_group.arn
}