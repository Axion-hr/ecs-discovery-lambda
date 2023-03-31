resource "aws_iam_policy" "execution_policy" {
  name = "AxionLambdaExecutionPolicy-${var.lambda_name}"
  policy = "${file("ecs-service-discovery.policy.json")}"
  
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "AxionLambdaExecutionRole-${var.lambda_name}"
  # assume_role_policy = data.aws_iam_policy_document.assume_role.json
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "execution_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.execution_policy.arn
}


data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${var.lambda_name}.py"
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "lambda" {
  filename         = "lambda_function_payload.zip"
  function_name    = "${var.lambda_name}"
  role             = aws_iam_role.iam_for_lambda.arn
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.9"
  handler          = "${var.lambda_name}.lambda_handler"
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = 30
  lifecycle {
    prevent_destroy = false
  }
}

