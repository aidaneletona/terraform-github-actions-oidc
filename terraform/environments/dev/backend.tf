terraform {
  backend "s3" {
    bucket       = "terraform-oidc-state-aidan"
    key          = "dev/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}