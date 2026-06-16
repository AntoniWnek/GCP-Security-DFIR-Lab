# INGRESS WEB: Publicly accessible Web Traffic (HTTP/HTTPS) for the vulnerable app
resource "google_compute_firewall" "allow_ingress_web" {
  name    = "allow-ingress-web"
  network = google_compute_network.dfir_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  # 0.0.0.0/0 means ANY IP address can view the website
  source_ranges = ["0.0.0.0/0"]

  target_tags   = ["bastion"]
}

# INGRESS SSH: Restricts administrative access strictly to the Admin's IP
resource "google_compute_firewall" "allow_ingress_ssh" {
  name    = "allow-ingress-ssh"
  network = google_compute_network.dfir_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Restricted by the variable in terraform.tfvars
  source_ranges = [var.admin_ip]

  target_tags   = ["bastion"]
}

# EGRESS - BASELINE: Blocks all other outbound traffic initiated from the DMZ (Zero Trust)
resource "google_compute_firewall" "deny_egress_dmz" {
  name      = "deny-egress-dmz"
  network   = google_compute_network.dfir_vpc.id
  direction = "EGRESS"

  # Lower priority (higher number), acts as a catch-all net
  priority = 1000

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

