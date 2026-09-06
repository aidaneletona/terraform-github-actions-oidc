variable "bucket_name" {
  type    = string
  default = "terraform-oidc-demo-aidan"
}

variable "name" {
  type    = string
  default = "Terraform OIDC Demo"
}

variable "project" {
  type    = string
  default = "terraform-github-actions-oidc"
}

variable "environment" {
  type    = string
  default = "Dev"
}