## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 0.2 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | AWS account ID | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name for the ressources | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region (where to deploy everything) | `string` | n/a | yes |
| <a name="input_slack_settings"></a> [slack\_settings](#input\_slack\_settings) | Slack channel ID and workplace ID | <pre>object({<br>    slack_channel_id : string<br>    slack_workspace_id : string<br>  })</pre> | n/a | yes |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | ARN of the SNS topic for the alerting | `string` | n/a | yes |
