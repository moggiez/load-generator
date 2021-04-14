resource "aws_cloudwatch_event_rule" "catch_all_lambda" {
  event_bus_name = var.eventbus.name
  name           = "${var.application}-${var.name}"
  description    = "Catch all events on event bus with type and send them to lambda function"

  event_pattern = jsonencode(
    {
      "account" : ["${var.account}"],
      "detail-type" : var.detail_types
    }
  )

  tags = {
    Project = var.application
  }
}

resource "aws_cloudwatch_event_target" "call_lambda" {
  event_bus_name = var.eventbus.name
  rule           = aws_cloudwatch_event_rule.catch_all_lambda.name
  target_id      = "MoggiezDriver"
  arn            = var.lambda.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = format("arn:aws:events:${var.region}:${var.account}:rule/%s/%s", var.eventbus.name, aws_cloudwatch_event_rule.catch_all_lambda.name)
}
