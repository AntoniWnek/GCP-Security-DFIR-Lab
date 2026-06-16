# AUTOMATION: Generate a dynamic, cryptographically secure SSH key pair inside Terraform memory
# This replaces loose local files and guarantees pristine key formatting without manual steps.
resource "tls_private_key" "hacker_key" {
  algorithm = "ED25519"
}

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

  # Automates the deployment of a vulnerable web app and introduces an SSH key vulnerability
  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y docker.io
    systemctl start docker
    systemctl enable docker

    # VULNERABILITY: Admin left a private SSH key mapped to the web directory
    mkdir -p /tmp/vuln_ssh
    # Terraform injects the dynamically generated private key directly from memory
    echo "${tls_private_key.hacker_key.private_key_openssh}" > /tmp/vuln_ssh/id_ed25519

    # Setting strict permissions required by SSH, mapped to www-data user (ID 33)
    chmod 600 /tmp/vuln_ssh/id_ed25519
    chown 33:33 /tmp/vuln_ssh/id_ed25519

    # FOOLPROOF FIX: Create a custom Dockerfile using standard echo to avoid whitespace issues
    # The base image uses Debian Stretch (EOL), so we must update the apt sources to the archive.
    echo 'FROM vulnerables/web-dvwa' > /tmp/Dockerfile
    echo 'RUN rm -rf /etc/apt/sources.list.d/* && echo "deb http://archive.debian.org/debian stretch main" > /etc/apt/sources.list && apt-get update -o Acquire::Check-Valid-Until=false && apt-get install -y --allow-unauthenticated openssh-client' >> /tmp/Dockerfile

    # Build the image locally (this runs synchronously and guarantees SSH is there)
    docker build -t custom-dvwa /tmp/
    
    # Run the customized vulnerable container and mount the exposed SSH key to the uploads directory
    docker run -d -p 80:80 -v /tmp/vuln_ssh:/var/www/html/hackable/uploads/.ssh custom-dvwa
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

  # Force disable GCP OS Login to ensure our manually injected local SSH keys are accepted
  metadata = {
    enable-oslogin = "FALSE"
  }

  # Startup script installs audit daemon, creates user manually, and injects keys
  metadata_startup_script = <<-EOF
    #!/bin/bash
    # Update package lists and install linux audit framework
    apt-get update
    apt-get install -y auditd audispd-plugins
    systemctl enable auditd
    systemctl start auditd

    # FIX: Manually create the user to avoid race conditions with GCP Guest Agent
    useradd -m -s /bin/bash admin || true
    mkdir -p /home/admin/.ssh
    
    # VULNERABILITY INJECTION: Public key matching the compromised private key on the Bastion
    # Terraform injects the matching public key directly from memory
    echo "${tls_private_key.hacker_key.public_key_openssh}" > /home/admin/.ssh/authorized_keys
    
    # Perfect permissions are MANDATORY for SSH to accept the key (StrictModes)
    chmod 700 /home/admin/.ssh
    chmod 600 /home/admin/.ssh/authorized_keys

    # HONEYTOKEN: Create a fake backup directory and insert dummy credentials
    mkdir -p /home/admin/backup
    echo "root_db: T@jneH@slo123!" > /home/admin/backup/hasla.txt
    echo "ssh_prod: ProdKey2025" >> /home/admin/backup/hasla.txt

    # Restore correct ownership so SSH StrictModes accepts the injected keys
    chown -R admin:admin /home/admin
    chmod 644 /home/admin/backup/hasla.txt

    # DFIR ALERT: Inject a persistent auditd rule to monitor the honeytoken
    # -w monitors the file path
    # -p rwa triggers on Read, Write, or Attribute changes
    # -k assigns a unique filter key for SIEM/BigQuery indexing
    auditctl -w /home/admin/backup/hasla.txt -p rwa -k HONEYTOKEN_TRIGGERED
  EOF
}
