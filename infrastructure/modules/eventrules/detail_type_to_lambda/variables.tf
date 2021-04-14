variable "application" {
  type        = string
  description = "Application Name"
}

variable "account" {
  type        = string
  description = "AWS account id"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "name" {
  type = string
}

variable "detail_types" {
  type = list(any)
}

variable "eventbus" {
}

variable "lambda" {
}