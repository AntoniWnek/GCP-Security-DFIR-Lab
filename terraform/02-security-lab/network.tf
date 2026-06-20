# VPC (Virtual Private Cloud)
resource "google_compute_network" "dfir_vpc" {
  name                    = "dfir-vpc"
  # Automatic subnets disabled for strict IP space control (10.0.0.0/16)
  auto_create_subnetworks = false 
  description             = "Custom VPC for Security DFIR Lab"
}

# DMZ SUBNET (10.0.1.0/24)
resource "google_compute_subnetwork" "dmz_subnet" {
  name          = "dmz-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "europe-central2"
  network       = google_compute_network.dfir_vpc.id

  # VPC Flow Logs configured for 100% visibility (Threat Hunting)
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 1.0 
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# INTERNAL SUBNET (10.0.2.0/24)
resource "google_compute_subnetwork" "internal_subnet" {
  name          = "internal-subnet"
  ip_cidr_range = "10.0.2.0/24"
  region        = "europe-central2"
  network       = google_compute_network.dfir_vpc.id

  # Enables internal instances to reach Google APIs (e.g., Cloud Logging) without public IPs
  private_ip_google_access = true

  # VPC Flow Logs
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 1.0
    metadata             = "INCLUDE_ALL_METADATA"
  }
}
