########################
# IAM Role and Policies
########################
data "aws_iam_policy_document" "assume_role_chatbot" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["chatbot.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "chatbot_slack_role" {
  name_prefix        = "${var.name}_chatbot_slack_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_chatbot.json
}

data "aws_iam_policy_document" "chatbot_slack_policy" {
  statement {
    actions = [
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*",
    ]
    resources = ["arn:aws:cloudwatch:${var.region}:${var.account_id}:*"]
  }
}

resource "aws_iam_role_policy" "chatbot_slack_role_policy" {
  name   = "${var.name}_chatbot_slack_role_policy"
  role   = aws_iam_role.chatbot_slack_role.id
  policy = data.aws_iam_policy_document.chatbot_slack_policy.json
}

##################################
# AWS Chatbot Slack Configuration
##################################
resource "awscc_chatbot_slack_channel_configuration" "slack_alerts" {
  configuration_name = "${var.name}_chatbot_slack_alerts"
  iam_role_arn       = aws_iam_role.chatbot_slack_role.arn
  slack_channel_id   = var.slack_settings.slack_channel_id
  slack_workspace_id = var.slack_settings.slack_workspace_id
  sns_topic_arns     = [var.sns_topic_arn]
}
