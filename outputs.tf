output "lambda_arn" {
  value = aws_lambda_function.lambda.arn
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts_sns_topic.arn
}
