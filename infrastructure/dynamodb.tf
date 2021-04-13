resource "aws_dynamodb_table" "playbooks" {
  name           = "playbooks2"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "customerId"

  attribute {
    name = "customerId"
    type = "S"
  }
}