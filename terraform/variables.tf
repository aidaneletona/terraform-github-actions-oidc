# -----------------------------------------------------------------------------
# Universal Variables
# -----------------------------------------------------------------------------

variable "project" {
  type    = string
  default = "terraform-github-actions-oidc"
}

variable "environment" {
  type    = string
  default = "Dev"
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
  default = "terraform-oidc-demo-aidan"
}

variable "demo_name" {
  type    = string
  default = "Terraform OIDC Demo"
}


variable "demo_purpose" {
  type    = string
  default = "Terraform Demo"
}

# -----------------------------------------------------------------------------
# State Variables
# -----------------------------------------------------------------------------

variable "state_bucket_name" {
  type    = string
  default = "terraform-oidc-state-aidan"
}

variable "state_name" {
  type    = string
  default = "Terraform OIDC State"
}

variable "state_purpose" {
  type    = string
  default = "Terraform State"
}
