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

resource "aws_s3_bucket" "raw_bucket" {
  bucket = var.raw_bucket
}

resource "aws_ecr_repository" "lambda_repo" {
  name = var.lambda_repo
}

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
  timeout       = 10
  image_uri     = "${aws_ecr_repository.lambda_repo.repository_url}:latest"
  package_type  = "Image"

  role = aws_iam_role.lambda_role.arn

  environment {
    variables = {
      RAW_BUCKET_NAME = var.raw_bucket
    }
  }
}

resource "aws_cloudwatch_event_rule" "event" {
  name                = var.lambda_event_rule
  schedule_expression = "cron(0 6 * * ? *)"
}

resource "aws_cloudwatch_event_target" "event_target" {
  rule = aws_cloudwatch_event_rule.event.name
  arn  = aws_lambda_function.lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.event.arn
}
