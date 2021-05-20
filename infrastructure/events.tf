# Creates event rules to link together events and lambdas
module "worker_source_to_log_group" {
  source       = "github.com/moggiez/terraform-modules/eventrules_source_to_log_group"
  application  = var.application
  account      = var.account
  eventbus     = aws_cloudwatch_event_bus.moggiez_load_test
  event_source = "Worker"
  log_group    = aws_cloudwatch_log_group.moggiez_worker
}

module "driver_source_to_log_group" {
  source       = "github.com/moggiez/terraform-modules/eventrules_source_to_log_group"
  application  = var.application
  account      = var.account
  eventbus     = aws_cloudwatch_event_bus.moggiez_load_test
  event_source = "Driver"
  log_group    = aws_cloudwatch_log_group.moggiez_driver
}

module "archiver_source_to_log_group" {
  source       = "github.com/moggiez/terraform-modules/eventrules_source_to_log_group"
  application  = var.application
  account      = var.account
  eventbus     = aws_cloudwatch_event_bus.moggiez_load_test
  event_source = "Archiver"
  log_group    = aws_cloudwatch_log_group.moggiez_archiver
}

module "user_call_event_to_lambda" {
  source       = "github.com/moggiez/terraform-modules/eventrules_detail_type_to_lambda"
  application  = var.application
  name         = "catch-type-to-lambda"
  account      = var.account
  region       = var.region
  detail_types = ["User Calls"]
  eventbus     = aws_cloudwatch_event_bus.moggiez_load_test
  lambda       = module.worker.lambda
}

module "worker_result_event_to_lambda" {
  source       = "github.com/moggiez/terraform-modules/eventrules_detail_type_to_lambda"
  application  = var.application
  name         = "catch-worker-results-to-lambda"
  account      = var.account
  region       = var.region
  detail_types = ["Worker Request Success", "Worker Request Failure"]
  eventbus     = aws_cloudwatch_event_bus.moggiez_load_test
  lambda       = module.archiver.lambda
}