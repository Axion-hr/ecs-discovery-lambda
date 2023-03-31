variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "environment" {
  type    = string
  default = "null"
}

variable "aws_account_id" { default = null }

variable "lambda_name" {
  type = string
  description = "Provide name for lambda function"
  default     = "ecs-service-discovery"  
}

variable "lambda_description" {
  type = string
  description = "Provide description of what this lambda is used for"
  default = "Lambda function handler that is used for service discovery by Prometheus"
}

variable "frontend_base_URL" {
  type = string
  description = "URL where  base URL for frontend app. e.g., http://cupo.dev.logpay.byaxion.com.s3-website.eu-central-1.amazonaws.com"
  default = null
}

variable "cluster_name" {
  default     = "logpay"
  type        = string
  description = "the name of an ECS cluster"
}

