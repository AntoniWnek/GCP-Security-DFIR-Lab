# LEAST PRIVILEGE: Empty Service Account for machines to prevent Metadata SSRF attacks
resource "google_service_account" "honeypot_sa" {
  account_id   = "honeypot-sa"
  display_name = "Honeypot Minimal Service Account"
  description  = "Empty Service Account for machines to prevent Metadata SSRF attacks"
}

# BASTION HOST / HONEYPOT (DMZ)
resource "google_compute_instance" "bastion_host" {
  name         = "bastion-dvwa"
  machine_type = "e2-micro"
  zone         = "europe-central2-a"

  # The tag that binds this machine to our zero-trust firewall rules
  tags = ["bastion"] 

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.dmz_subnet.id
    
    # Ephemeral public IP assignment
    access_config {
      # Leaving this block empty tells GCP to assign a dynamic public IP
    }
  }

# Attaching an empty service account
  service_account {
    email  = google_service_account.honeypot_sa.email
    scopes = ["cloud-platform"]
  }

  # Automates the deployment of a vulnerable web app for testing
  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y docker.io
    systemctl start docker
    systemctl enable docker
    docker run -d -p 80:80 vulnerables/web-dvwa
  EOF
}

# OUTPUT: Displays the assigned public IP in the terminal after deployment
output "bastion_public_ip" {
  value       = google_compute_instance.bastion_host.network_interface[0].access_config[0].nat_ip
  description = "The public IP address of the Bastion Host (DVWA)"
}

# INTERNAL TARGET SERVER (No Public IP)
resource "google_compute_instance" "target_server" {
  name         = "target-internal"
  machine_type = "e2-micro"
  zone         = "europe-central2-a"

  # Tag for potential future internal firewall rules
  tags = ["target"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    # Placing it in the internal subnet
    subnetwork = google_compute_subnetwork.internal_subnet.id
    
    # INTENTIONAL: No access_config block here 
    # This ensures the machine gets NO public IP address
  }

# Attaching an empty service account
  service_account {
    email  = google_service_account.honeypot_sa.email
    scopes = ["cloud-platform"]
  }

# Startup script installs audit daemon and provisions a canary file
  metadata_startup_script = <<-EOF
    #!/bin/bash
    # Update package lists and install linux audit framework
    apt-get update
    apt-get install -y auditd audispd-plugins
    systemctl enable auditd
    systemctl start auditd

    # HONEYTOKEN: Create a fake backup directory and insert dummy credentials
    mkdir -p /home/admin/backup
    echo "root_db: T@jneH@slo123!" > /home/admin/backup/hasla.txt
    echo "ssh_prod: ProdKey2025" >> /home/admin/backup/hasla.txt
    chmod 644 /home/admin/backup/hasla.txt

    # DFIR ALERT: Inject a persistent auditd rule to monitor the honeytoken
    # -w monitors the file path
    # -p rwa triggers on Read, Write, or Attribute changes
    # -k assigns a unique filter key for SIEM/BigQuery indexing
    auditctl -w /home/admin/backup/hasla.txt -p rwa -k HONEYTOKEN_TRIGGERED
  EOF
}
