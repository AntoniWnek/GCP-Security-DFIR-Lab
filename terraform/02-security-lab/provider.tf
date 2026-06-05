# TERRAFORM BLOCK: Required providers
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# PROVIDER BLOCK: Authentication and region setup
provider "google" {
  project = var.project_id
  region  = "europe-central2"
}
  
  
  
  
