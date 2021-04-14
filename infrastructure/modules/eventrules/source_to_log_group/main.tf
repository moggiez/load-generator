resource "aws_cloudwatch_event_rule" "source_to_log" {
  event_bus_name = var.eventbus.name
  name           = "${var.application}-source-${var.event_source}-to-logs"
  description    = "Catch all events on the event bus and log to CloudWatch Logs"

  event_pattern = jsonencode(
    {
      "account" : ["${var.account}"],
      "source" : ["${var.event_source}"]
    }
  )

  tags = {
    Project = var.application
  }
}

resource "aws_cloudwatch_event_target" "catch_all_log" {
  event_bus_name = var.eventbus.name
  rule           = aws_cloudwatch_event_rule.source_to_log.name
  target_id      = "MoggiezTestLogs_${var.event_source}"
  arn            = var.log_group.arn
}