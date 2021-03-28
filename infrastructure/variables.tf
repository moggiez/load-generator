variable "backend_name" {
  type    = string
  default = "moggiez"
}

variable "aws_access_key" {
  type      = string
  sensitive = true
}

variable "aws_secret_key" {
  type      = string
  sensitive = true
}

variable "dist_version" {
  type    = string
  default = "1.0.0"
}

variable "dist_dir" {
  type    = string
  default = "../dist"
}

variable "account" {
  type    = string
  default = "989665778089"
}

variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "application" {
  type    = string
  default = "Moggiez"
}