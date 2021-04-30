variable "s3_bucket" {
}

variable "timeout" {
  type    = number
  default = 3
}

variable "dist_dir" {
  type = string
}

variable "dist_version" {
  type    = string
  default = "1.0.0"
}