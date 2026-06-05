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

# RESOURCE BLOCK: BigQuery Dataset for Decoupled Telemetry
resource "google_bigquery_dataset" "soc_telemetry" {
  dataset_id                  = "soc_telemetry_logs"
  friendly_name               = "SOC Threat Hunting Dataset"
  description                 = "Stores security logs from Bastion Host and network layer (VPC Flow Logs)"
  location                    = "EU"
  
  delete_contents_on_destroy  = true 
}
