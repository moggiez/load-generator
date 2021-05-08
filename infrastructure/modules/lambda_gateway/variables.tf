variable "lambda" {

}

variable "api" {

}

variable "resource_path_part" {
  type = string
}

variable "http_method" {
  type    = string
  default = "GET"
}

variable "authorizer" {
  default = null
}