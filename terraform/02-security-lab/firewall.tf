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

# EGRESS: Blocks all outbound traffic initiated from the DMZ (Zero Trust)
resource "google_compute_firewall" "deny_egress_dmz" {
  name      = "deny-egress-dmz"
  network   = google_compute_network.dfir_vpc.id
  direction = "EGRESS"
  priority  = 1000

  deny {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
  target_tags        = ["bastion"]
}
