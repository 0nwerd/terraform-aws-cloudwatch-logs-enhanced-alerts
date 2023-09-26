//DYNAMODB TABLE
resource "aws_dynamodb_table" "errors_table" {
  name         = "${var.name}-errors_table"
  hash_key     = "error_message_hash"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "error_message_hash"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }
}

//SNS TOPIC
resource "aws_sns_topic" "alarm_lambdas_sns_topic" {
  name              = "${var.name}_alarm_sns_topic"
}

//SLACK INTEGRATION
module "slack_integration" {
    source = "./modules/slack_integration"

    count = length(var.slack_settings) > 0 ? 1 : 0

    name = var.name
    account_id = var.account_id
    region = var.region

    slack_channel_id = ""
    slack_workspace_id = ""
}

//IAM ROLE & POLICIES
data "aws_iam_policy_document" "assume_role_lambda" {
  statement {
    actions = ["sts:AssumeRole"]
		principals = [{
			"Service" : "lambda.amazonaws.com"
		}]
  }
}

resource "aws_iam_role" "logs_errors_alarm_trigger_role" {
  name_prefix         = "logs_errors_alarm_trigger_role"
  assume_role_policy  = data.aws_iam_policy_document.assume_role_lambda.json
}

data "aws_iam_policy_document" "logs_errors_alarm_trigger_policy" {
  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:GetItem",
      "dynamodb:Scan",
      "dynamodb:Query",
    ]
    resources = [aws_dynamodb_table.errors_table.arn]
  }

  statement {
    actions = [
      "sns:Publish",
    ]
    resources = [aws_sns_topic.alarm_lambdas_sns_topic.arn]
  }
}

resource "aws_iam_role_policy" "logs_errors_alarm_trigger_policy" {
  name_prefix = "logs_errors_alarm_trigger"
  role        = aws_iam_role.logs_errors_alarm_trigger_role.id
  policy      = data.aws_iam_policy_document.logs_errors_alarm_trigger_policy.json
}

//LAMBDA
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda/logs_errors_alarm_trigger.py"
  output_path = "lambda/logs_errors_alarm_trigger.zip"
}

module "logs_errors_alarm_trigger_sg" {
  source      = "../modules/security_group"
  name_prefix = "logs_errors_alarm_trigger"
  description = "Security group for the logs alarm lambda"
  vpc_id      = module.vpc_module.vpc_id
}

resource "aws_lambda_function" "logs_errors_alarm_trigger" {
  function_name    = "CloudWatchLogsAlarmTrigger"
  description      = "Trigger alarms based on Cloudwatch Logs trigger"
  role             = aws_iam_role.logs_errors_alarm_trigger_role.arn
  handler          = "logs_errors_alarm_trigger.lambda_handler"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 300

  runtime = "python3.8"

  environment {
    variables = {
      SNS_ARN        = aws_sns_topic.alarm_lambdas_sns_topic.arn
      DYNAMODB_TABLE = aws_dynamodb_table.errors_table.name
      MAX            = 600 //10 minutes
    }
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_logs" {
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.logs_errors_alarm_trigger.function_name
  principal      = "logs.amazonaws.com"
  source_account = "ACCOUNT_ID"
  source_arn     = "arn:aws:logs:${var.region}:${var.account_id}:log-group:*"
}
