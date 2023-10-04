terraform {
  required_version = "> 1.4.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "> 4.0.0"
    }

    awscc = {
      source  = "hashicorp/awscc"
      version = "> 0.2"
    }
  }
}
