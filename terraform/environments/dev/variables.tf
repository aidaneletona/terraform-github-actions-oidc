# -----------------------------------------------------------------------------
# Universal Variables
# -----------------------------------------------------------------------------

variable "project" {
  type    = string
  default = "terraform-github-actions-oidc"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "region" {
  type    = string
  default = "us-east-2"
}


# -----------------------------------------------------------------------------
# S3 Demo Variables
# -----------------------------------------------------------------------------

variable "demo_bucket_name" {
  type    = string
  default = "terraform-oidc-demo-aidan-dev"
}

variable "demo_purpose" {
  type    = string
  default = "Terraform Demo"
}
