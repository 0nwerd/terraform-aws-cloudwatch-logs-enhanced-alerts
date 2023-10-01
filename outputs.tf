output "lambda_arn" {
  description = "ARN of the Lambda function (use it with CloudWatch Logs Subscription Filter)"
  value       = aws_lambda_function.lambda.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic (if you need to setup other notifications than Slack)"
  value       = aws_sns_topic.alerts_sns_topic.arn
}
