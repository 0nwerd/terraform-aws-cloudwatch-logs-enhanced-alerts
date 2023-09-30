locals {
  default_environment_variables = {
    SNS_ARN        = aws_sns_topic.alerts_sns_topic.arn
    DYNAMODB_TABLE = aws_dynamodb_table.logs_errors_table.name
    MAX            = 600
  }
  lambda_environment_variables = merge(local.default_environment_variables, var.lambda_environment_variables)
}

#######################################
# DynamoDB table (with DynamoDB Stream)
#######################################
resource "aws_dynamodb_table" "logs_errors_table" {
  name             = "logs_errors_table"
  hash_key         = "error_message_hash"
  billing_mode     = "PAY_PER_REQUEST"
  stream_enabled   = true
  stream_view_type = "OLD_IMAGE"

  attribute {
    name = "error_message_hash"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }
}

############
# SNS Topic
############
resource "aws_sns_topic" "alerts_sns_topic" {
  name = "${var.name}_sns_topic"
}

###########################
# Slack integration module
###########################
module "slack_integration" {
  source = "./modules/slack_integration"

  count = length(var.slack_settings) > 0 ? 1 : 0

  name       = var.name
  account_id = var.account_id
  region     = var.region

  sns_topic_arn = aws_sns_topic.alerts_sns_topic.arn

  slack_settings = var.slack_settings
}

###################################
# Lambda function Roles & Policies
###################################
data "aws_iam_policy_document" "assume_role_lambda" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name_prefix         = "${var.name}_role"
  assume_role_policy  = data.aws_iam_policy_document.assume_role_lambda.json
  managed_policy_arns = var.vpc_subnet_ids != null && var.vpc_security_group_ids != null ? ["arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"] : null
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:GetItem",
      "dynamodb:Scan",
      "dynamodb:Query",
    ]
    resources = [aws_dynamodb_table.logs_errors_table.arn]
  }

  statement {
    actions = [
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:DescribeStream",
      "dynamodb:ListStreams"
    ]
    resources = ["${aws_dynamodb_table.logs_errors_table.arn}/stream/*"]
  }

  statement {
    actions = [
      "sns:Publish",
    ]
    resources = [aws_sns_topic.alerts_sns_topic.arn]
  }
}

resource "aws_iam_role_policy" "lambda_policy" {
  name_prefix = var.name
  role        = aws_iam_role.lambda_role.id
  policy      = data.aws_iam_policy_document.lambda_policy.json
}

##################
# Lambda function
##################
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = var.lambda_code_path
  output_path = "build.zip"
}

resource "aws_lambda_function" "lambda" {
  function_name    = var.name
  description      = "Trigger alerts based on Cloudwatch Logs Subscription Filter trigger"
  role             = aws_iam_role.lambda_role.arn
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 10

  runtime = var.lambda_runtime

  dynamic "environment" {
    for_each = length(keys(local.lambda_environment_variables)) == 0 ? [] : [true]
    content {
      variables = local.lambda_environment_variables
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_subnet_ids != null && var.vpc_security_group_ids != null ? [true] : []
    content {
      security_group_ids = var.vpc_security_group_ids
      subnet_ids         = var.vpc_subnet_ids
    }
  }

  depends_on = [
    aws_dynamodb_table.logs_errors_table,
    aws_sns_topic.alerts_sns_topic,
    aws_iam_role.lambda_role
  ]
}

resource "aws_lambda_permission" "allow_cloudwatch_logs" {
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.lambda.function_name
  principal      = "logs.amazonaws.com"
  source_account = var.account_id
  source_arn     = "arn:aws:logs:${var.region}:${var.account_id}:log-group:*"
}

resource "aws_lambda_event_source_mapping" "trigger" {
  event_source_arn  = aws_dynamodb_table.logs_errors_table.stream_arn
  function_name     = aws_lambda_function.lambda.function_name
  starting_position = "LATEST"

  filter_criteria {
    filter {
      pattern = "{\"userIdentity\":{\"type\":[\"Service\"],\"principalId\":[\"dynamodb.amazonaws.com\"]}}"
    }
  }
}
