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
  project = "project-61690e78-c96f-4e67-82a"
  region  = "europe-central2"
}
  
  
  
  
