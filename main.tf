terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"

  backend "s3" {
    region = "eu-central-1"
  }
}

provider "aws" {
  region = "eu-central-1"
}



data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "access_policy" {
  statement {
    actions = [
      "ecs:ListTasks",
      "ecs:DescribeTasks",
      "ecs:DescribeTaskDefinition",
      "ecs:ListClusters"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:eu-central-1:*:log-group:/aws/lambda/${var.lambda_name}/*"]
  }

  statement {
    actions = [
      "logs:CreateLogGroup"
    ]
    resources = ["arn:aws:logs:eu-central-1:*:*"]
  }

  statement {
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:*:*:parameter/deployment/stage"]
  }
}


resource "aws_iam_role" "iam_for_lambda" {
  name               = "AxionLambdaExecutionRole-${var.lambda_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "ecs-discovery.py"
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "lambda" {
  filename         = "lambda_function_payload.zip"
  function_name    = "ecs-service-discovery"
  role             = aws_iam_role.iam_for_lambda.arn
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.9"
  handler          = "lambda_handler"
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = 30
  lifecycle {
    prevent_destroy = false
  }
}
