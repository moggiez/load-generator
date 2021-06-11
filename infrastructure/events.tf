# Creates event rules to link together events and lambdas
module "worker_source_to_log_group" {
  source       = "git@github.com:moggiez/terraform-modules.git//eventrules_source_to_log_group"
  application  = var.application
  account      = var.account
  eventbus     = aws_cloudwatch_event_bus.moggiez_load_test
  event_source = "Worker"
  log_group    = aws_cloudwatch_log_group.moggiez_worker
}

module "driver_source_to_log_group" {
  source       = "git@github.com:moggiez/terraform-modules.git//eventrules_source_to_log_group"
  application  = var.application
  account      = var.account
  eventbus     = aws_cloudwatch_event_bus.moggiez_load_test
  event_source = "Driver"
  log_group    = aws_cloudwatch_log_group.moggiez_driver
}

module "archiver_source_to_log_group" {
  source       = "git@github.com:moggiez/terraform-modules.git//eventrules_source_to_log_group"
  application  = var.application
  account      = var.account
  eventbus     = aws_cloudwatch_event_bus.moggiez_load_test
  event_source = "Archiver"
  log_group    = aws_cloudwatch_log_group.moggiez_archiver
}

module "user_call_event_to_lambda" {
  source       = "git@github.com:moggiez/terraform-modules.git//eventrules_detail_type_to_lambda"
  application  = var.application
  name         = "catch-type-to-lambda"
  account      = var.account
  region       = var.region
  detail_types = ["User Calls"]
  eventbus     = aws_cloudwatch_event_bus.moggiez_load_test
  lambda       = module.worker.lambda
}

module "worker_result_event_to_lambda" {
  source       = "git@github.com:moggiez/terraform-modules.git//eventrules_detail_type_to_lambda"
  application  = var.application
  name         = "catch-worker-results-to-lambda"
  account      = var.account
  region       = var.region
  detail_types = ["Worker Request Success", "Worker Request Failure"]
  eventbus     = aws_cloudwatch_event_bus.moggiez_load_test
  lambda       = module.archiver.lambda
}

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