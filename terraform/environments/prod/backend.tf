terraform {
  backend "s3" {
    bucket  = "terraform-oidc-state-aidan"
    key     = "prod/terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
}