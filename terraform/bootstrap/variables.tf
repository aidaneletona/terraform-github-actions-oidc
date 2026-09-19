# -----------------------------------------------------------------------------
# State Variables
# -----------------------------------------------------------------------------

variable "state_bucket_name" {
  type    = string
  default = "terraform-oidc-state-aidan"
}

variable "state_purpose" {
  type    = string
  default = "Terraform State"
}

variable "project" {
  type    = string
  default = "terraform-github-actions-oidc"
}

variable "environment" {
  type    = string
  default = "Root"
}