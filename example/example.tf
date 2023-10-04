data "aws_caller_identity" "current" {}

module "example" {
  source = "../"

  name       = "example"
  account_id = data.aws_caller_identity.current.account_id
  region     = "eu-central-1"
  slack_settings = {
    slack_channel_id   = "00000000000" //Replace with your own channel ID
    slack_workspace_id = "00000000000" //Replace with your own workspace ID
  }
}
