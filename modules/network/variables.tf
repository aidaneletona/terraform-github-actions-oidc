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