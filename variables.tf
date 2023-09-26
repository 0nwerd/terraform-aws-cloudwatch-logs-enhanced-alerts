variable "name" {
  type = string
}

variable "account_id" {
  type = string
}

variable "region" {
  type = string
}

variable "slack_settings" {
  type = list(object({
    slack_channel_id : string
    slack_workspace_id : string
  }))

  default = []

  validation {
    condition = length(var.slack_settings) == 1
    error_message = "Only one Slack channel is authorized here."
  }
}