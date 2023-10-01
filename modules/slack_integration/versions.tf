terraform {
  required_version = "~> 1.4.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 0.61"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}
