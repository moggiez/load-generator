variable "aws_access_key" {
    type = string
    sensitive   = true
}

variable "aws_secret_key" {
    type = string
    sensitive = true
}

variable "lambda_version" {
  type = string
  default = "1.0.0"
}

variable "dist_dir" {
  type = string
  default = "../dist"
}