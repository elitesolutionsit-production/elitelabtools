## Providers definition

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.34.0"
    }
  }
  required_version = ">=0.13"
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}