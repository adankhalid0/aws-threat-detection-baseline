terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "tfstate-cloudsec-khalid-7291"
    key            = "aws-threat-detection-baseline/dev/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "tfstate-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "aws-threat-detection-baseline"
      ManagedBy   = "terraform"
      Environment = "dev"
    }
  }
}
