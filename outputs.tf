output "lambda_arn" {
    value = aws_lambda_function.logs_errors_alarm_trigger.arn
}