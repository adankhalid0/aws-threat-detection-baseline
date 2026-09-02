terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Reuses the same remote-state pattern as aws-cloud-security-baseline
  # rather than standing up a second S3 bucket + DynamoDB table just for
  # this project's state -- fill in the bucket/table you already created
  # in that project's terraform/bootstrap, with a different `key` so the
  # two projects' state files stay isolated from each other.
  backend "s3" {
    bucket         = "<your-tfstate-bucket>"
    key            = "aws-threat-detection-baseline/dev/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "<your-lock-table>"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}
