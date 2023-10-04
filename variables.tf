variable "name" {
  description = "Name for the ressources"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "region" {
  description = "AWS region (where to deploy everything)"
  type        = string
}

variable "slack_settings" {
  description = "Slack channel ID and workplace ID"
  type = object({
    slack_channel_id : string
    slack_workspace_id : string
  })
  default = null
}

variable "lambda_code_path" {
  description = "Path of the lambda function code"
  type        = string
  default     = "logs_alerts.py"
}

variable "lambda_runtime" {
  description = "Runtime for the lambda"
  type        = string
  default     = "python3.8"
}

variable "lambda_environment_variables" {
  description = "A map that defines environment variables for the Lambda Function."
  type        = map(string)
  default     = {}
}

variable "vpc_subnet_ids" {
  description = "List of subnet IDs when the function should run in a VPC"
  type        = list(string)
  default     = null
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs when the function should run in a VPC"
  type        = list(string)
  default     = null
}
