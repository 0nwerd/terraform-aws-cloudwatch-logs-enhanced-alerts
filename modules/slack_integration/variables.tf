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

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for the alerting"
  type        = string
}

variable "slack_settings" {
  description = "Slack channel ID and workplace ID"
  type = object({
    slack_channel_id : string
    slack_workspace_id : string
  })
}
