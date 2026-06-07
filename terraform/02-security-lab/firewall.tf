# INGRESS: Allows SSH and Web traffic exclusively from admin's public IP
resource "google_compute_firewall" "allow_ingress_bastion" {
  name    = "allow-ingress-bastion"
  network = google_compute_network.dfir_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

  # Uses the variable stored safely in terraform.tfvars
  source_ranges = [var.admin_ip]

  # Applies this rule only to machines with the "bastion" tag
  target_tags   = ["bastion"]
}

# EGRESS - BASELINE: Blocks all other outbound traffic initiated from the DMZ (Zero Trust)
resource "google_compute_firewall" "deny_egress_dmz" {
  name      = "deny-egress-dmz"
  network   = google_compute_network.dfir_vpc.id
  direction = "EGRESS"
  
  # Lower priority (higher number), acts as a catch-all net
  priority  = 1000

  deny {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
  target_tags        = ["bastion"]
}

# EGRESS - VULNERABLE: Allows outbound traffic from the DMZ to the Internal subnet
resource "google_compute_firewall" "allow_dmz_to_internal_vulnerable" {
  name      = "allow-dmz-to-internal-vulnerable"
  network   = google_compute_network.dfir_vpc.id
  direction = "EGRESS"
  priority  = 900

  allow {
    protocol = "all"
  }

  destination_ranges = ["10.0.2.0/24"]
  target_tags        = ["bastion"]
}

# INGRESS - VULNERABLE: Allows incoming traffic from the DMZ subnet to the Internal subnet
resource "google_compute_firewall" "allow_ingress_internal_vulnerable" {
  name      = "allow-ingress-internal-vulnerable"
  network   = google_compute_network.dfir_vpc.id
  direction = "INGRESS"

  allow {
    protocol = "all"
  }

  source_ranges = ["10.0.1.0/24"] 
}
