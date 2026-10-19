terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0"
    }
  }
}

provider "aws" {
  alias               = "account_a"
  region              = var.aws_region
  profile             = var.account_a_profile
  allowed_account_ids = [var.account_a_id]
}

provider "aws" {
  alias               = "account_b"
  region              = var.aws_region
  profile             = var.account_b_profile
  allowed_account_ids = [var.account_b_id]
}

data "aws_partition" "account_a" {
  provider = aws.account_a
}
