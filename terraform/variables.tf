variable "raw_bucket" {
  type    = string
  default = "de03-raw-data"
}

variable "lakehouse_bucket" {
  type    = string
  default = "de03-lakehouse"
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

variable "glue_role" {
  type    = string
  default = "de03-glue-role"
}

variable "glue_source_bucket" {
  type    = string
  default = "de03-glue-source"
}

variable "glue_bronze_database" {
  type    = string
  default = "de03-bronze"
}

variable "glue_silver_database" {
  type    = string
  default = "de03-silver"
}

variable "glue_gold_database" {
  type    = string
  default = "de03-gold"
}

variable "s3_location_bronze_database" {
  type    = string
  default = "de03-gold"
}

variable "s3_location_silver_database" {
  type    = string
  default = "de03-gold"
}

variable "s3_location_gold_database" {
  type    = string
  default = "de03-gold"
}



