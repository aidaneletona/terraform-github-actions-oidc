terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> "
    }
  }

  backend "s3" {
    bucket  = "terraform-oidc-state-aidan"
    key     = "terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
}