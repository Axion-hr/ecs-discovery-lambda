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

data "aws_vpc" "app_vpc" {
  filter {
    name   = "tag:Name"
    values = ["app-vpc_TF"]
  }
}


data "aws_lb" "netLBinternal" {
  name = "${var.cluster_name}-nlb"
}

data "aws_lb" "internalLB" {
  name = "${var.cluster_name}-LBinternal"
}

data "aws_lb_listener" "internalLB" {
  load_balancer_arn = data.aws_lb.internalLB.arn
  port              = 443
}

data "aws_ssm_parameter" "stage" {
  name = "/deployment/stage"
}

data "aws_route53_zone" "selected" {
  name         = "${data.aws_ssm_parameter.stage.value}.logpay.byaxion.com"  
}


resource "aws_route53_record" "r53-entry" {
  zone_id = data.aws_route53_zone.selected.id
  name    = "${var.lambda_name}.${data.aws_ssm_parameter.stage.value}.logpay.byaxion.com"
  type    = "CNAME"
  ttl     = "60"
  records = [data.aws_lb.internalLB.dns_name]
}