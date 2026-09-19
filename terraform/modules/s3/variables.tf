# -----------------------------------------------------------------------------
# Universal Variables
# -----------------------------------------------------------------------------

variable "project" {
  type    = string
  default = "terraform-github-actions-oidc"
}

variable "region" {
  type    = string
  default = "us-east-2"
}

variable "demo_purpose" {
  type    = string
  default = "Terraform Demo"
}

# -----------------------------------------------------------------------------
# S3 Demo Variables
# -----------------------------------------------------------------------------

variable "demo_bucket" {
  type = string
}

variable "environment" {
  type = string
}





