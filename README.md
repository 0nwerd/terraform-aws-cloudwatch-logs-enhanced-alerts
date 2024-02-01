## 📝 Medium Article
For more information about this module, check out this article: [https://medium.com/@louis-fiori/cloudwatch-logs-enhanced-alerts-a50ea08d0845](https://medium.com/@louis-fiori/cloudwatch-logs-enhanced-alerts-a50ea08d0845)
 
 ## 🔗 Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 0.2 |

## ➡️ Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | AWS account ID | `string` | n/a | yes |
| <a name="input_lambda_code_path"></a> [lambda\_code\_path](#input\_lambda\_code\_path) | Path of the Lambda function code | `string` | `"logs_alerts.py"` | no |
| <a name="input_lambda_environment_variables"></a> [lambda\_environment\_variables](#input\_lambda\_environment\_variables) | A map that defines environment variables for the Lambda Function. | `map(string)` | `{}` | no |
| <a name="input_lambda_handler"></a> [lambda\_handler](#input\_lambda\_handler) | Handler for the Lambda | `string` | `"logs_alerts.lambda_handler"` | no |
| <a name="input_lambda_runtime"></a> [lambda\_runtime](#input\_lambda\_runtime) | Runtime for the Lambda | `string` | `"python3.8"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name for the ressources | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region (where to deploy everything) | `string` | n/a | yes |
| <a name="input_slack_settings"></a> [slack\_settings](#input\_slack\_settings) | Slack channel ID and workplace ID | <pre>object({<br>    slack_channel_id : string<br>    slack_workspace_id : string<br>  })</pre> | `null` | no |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | List of security group IDs when the function should run in a VPC | `list(string)` | `null` | no |
| <a name="input_vpc_subnet_ids"></a> [vpc\_subnet\_ids](#input\_vpc\_subnet\_ids) | List of subnet IDs when the function should run in a VPC | `list(string)` | `null` | no |

## ⬅️ Outputs

| Name | Description |
|------|-------------|
| <a name="output_lambda_arn"></a> [lambda\_arn](#output\_lambda\_arn) | ARN of the Lambda function (use it with CloudWatch Logs Subscription Filter) |
| <a name="output_sns_topic_arn"></a> [sns\_topic\_arn](#output\_sns\_topic\_arn) | ARN of the SNS topic (if you need to setup other notifications than Slack) |
