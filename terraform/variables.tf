variable "raw_bucket" {
  type    = string
  default = "de03-raw-data"
}

variable "lambda_repo" {
  type    = string
  default = "de03-lambda-repo"
}

variable "lambda_role" {
  type    = string
  default = "de03-lambda-role"
}

variable "lambda" {
  type    = string
  default = "de03-upload-s3"
}

variable "lambda_event_rule" {
  type    = string
  default = "de03-trigger-lambda"
}
