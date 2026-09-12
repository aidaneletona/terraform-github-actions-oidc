# -----------------------------------------------------------------------------
# S3 Module 
# ----------------------------------------------------------------------------- 

module "s3" {
source = "./modules/s3"

project = var.project

environment = var.environment

}


# -----------------------------------------------------------------------------
# Network Module
# ----------------------------------------------------------------------------- 

module "network" {
  source = "./modules/network"

  project     = var.project
  environment = var.environment
}