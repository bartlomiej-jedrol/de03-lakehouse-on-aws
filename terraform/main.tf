terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "bj-terraform-states"
    key     = "state-de03-lakehouse-on-aws/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }
}

# S3 bucket raw data
resource "aws_s3_bucket" "raw_bucket" {
  bucket = var.raw_bucket
}


# S3 bucket lakehouse
resource "aws_s3_bucket" "lakehouse_bucket" {
  bucket = var.lakehouse_bucket
}

resource "aws_s3_object" "bronze_folder" {
  bucket = aws_s3_bucket.lakehouse_bucket.id
  key    = "lakehouse/bronze"
}

resource "aws_s3_object" "silver_folder" {
  bucket = aws_s3_bucket.lakehouse_bucket.id
  key    = "lakehouse/silver"
}

resource "aws_s3_object" "gold_folder" {
  bucket = aws_s3_bucket.lakehouse_bucket.id
  key    = "lakehouse/gold"
}


# ECR lambda repo
resource "aws_ecr_repository" "lambda_repo" {
  name = var.lambda_repo
}


# Lambda
resource "aws_iam_role" "lambda_role" {
  name = var.lambda_role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess", "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole", "arn:aws:iam::aws:policy/CloudWatchEventsFullAccess", "arn:aws:iam::aws:policy/AmazonS3FullAccess"]
}

resource "aws_lambda_function" "lambda" {
  function_name = var.lambda
  timeout       = 30
  image_uri     = "${aws_ecr_repository.lambda_repo.repository_url}:latest"
  package_type  = "Image"

  role = aws_iam_role.lambda_role.arn

  environment {
    variables = {
      RAW_BUCKET_NAME = var.raw_bucket
    }
  }
}


# CloudWatch event
resource "aws_cloudwatch_event_rule" "event" {
  name                = var.lambda_event_rule
  schedule_expression = "rate(2 hours)"
}

resource "aws_cloudwatch_event_target" "event_target" {
  rule = aws_cloudwatch_event_rule.event.name
  arn  = aws_lambda_function.lambda.arn
}


# Lambda permission for CloudWatch events
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.event.arn
}


# Glue
resource "aws_iam_role" "glue_role" {
  name = var.glue_role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "glue.amazonaws.com"
      }
    }]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonS3FullAccess", "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"]
}

# S3 bucket for glue script
resource "aws_s3_bucket" "glue_source_bucket" {
  bucket = var.glue_source_bucket
}

# Glue databases for the lakehouse
resource "aws_glue_catalog_database" "bronze_database" {
  name         = var.glue_bronze_database
  location_uri = "s3://de03-lakehouse/lakehouse/bronze"
}

resource "aws_glue_catalog_database" "silver_database" {
  name         = var.glue_silver_database
  location_uri = "s3://de03-lakehouse/lakehouse/silver"
}

resource "aws_glue_catalog_database" "gold_database" {
  name         = var.glue_gold_database
  location_uri = "s3://de03-lakehouse/lakehouse/gold"
}
