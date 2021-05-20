# Log groups
resource "aws_cloudwatch_log_group" "moggiez_worker" {
  name = "/aws/events/moggiez_worker"
}

resource "aws_cloudwatch_log_group" "moggiez_driver" {
  name = "/aws/events/moggiez_driver"
}

resource "aws_cloudwatch_log_group" "moggiez_archiver" {
  name = "/aws/events/moggiez_archiver"
}

resource "aws_cloudwatch_event_bus" "moggiez_load_test" {
  name = "moggiez-load-test"
}