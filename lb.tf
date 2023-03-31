resource "aws_lb_listener_rule" "listener-rule" {
  listener_arn = data.aws_lb_listener.internalLB.arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
  condition {
    host_header {
      values = ["${var.lambda_name}.${data.aws_ssm_parameter.stage.value}.logpay.byaxion.com"]
    }
  }
}

resource "aws_lb_target_group" "tg" {
  name        = "${var.lambda_name}"
  target_type = "lambda"
}

resource "aws_lambda_permission" "with_lb" {
  statement_id  = "AllowExecutionFromlb"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.tg.arn
}

resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_lambda_function.lambda.arn
  depends_on       = [aws_lambda_permission.with_lb]
}


