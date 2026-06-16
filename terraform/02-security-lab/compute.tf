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

  tags = ["bastion"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.dmz_subnet.id
    access_config {}
  }

  service_account {
    email  = google_service_account.honeypot_sa.email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y docker.io
    systemctl start docker
    systemctl enable docker

    mkdir -p /tmp/vuln_ssh
    # Terraform injects the exact, pristine private key file here
    echo "${file("./dfir_key")}" > /tmp/vuln_ssh/id_ed25519

    chmod 600 /tmp/vuln_ssh/id_ed25519
    chown 33:33 /tmp/vuln_ssh/id_ed25519

    echo 'FROM vulnerables/web-dvwa' > /tmp/Dockerfile
    echo 'RUN rm -rf /etc/apt/sources.list.d/* && echo "deb http://archive.debian.org/debian stretch main" > /etc/apt/sources.list && apt-get update -o Acquire::Check-Valid-Until=false && apt-get install -y --allow-unauthenticated openssh-client' >> /tmp/Dockerfile

    docker build -t custom-dvwa /tmp/
    docker run -d -p 80:80 -v /tmp/vuln_ssh:/var/www/html/hackable/uploads/.ssh custom-dvwa
  EOF
}

output "bastion_public_ip" {
  value       = google_compute_instance.bastion_host.network_interface[0].access_config[0].nat_ip
  description = "The public IP address of the Bastion Host (DVWA)"
}

# INTERNAL TARGET SERVER (No Public IP)
resource "google_compute_instance" "target_server" {
  name         = "target-internal"
  machine_type = "e2-micro"
  zone         = "europe-central2-a"

  tags = ["target"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.internal_subnet.id
  }

  service_account {
    email  = google_service_account.honeypot_sa.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "FALSE"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y auditd audispd-plugins
    systemctl enable auditd
    systemctl start auditd

    # Directly create user and inject the public key without relying on GCP Metadata magic
    useradd -m -s /bin/bash admin || true
    mkdir -p /home/admin/.ssh
    
    # Terraform injects the exact, pristine public key file here
    echo "${file("./dfir_key.pub")}" > /home/admin/.ssh/authorized_keys
    
    chmod 700 /home/admin/.ssh
    chmod 600 /home/admin/.ssh/authorized_keys

    mkdir -p /home/admin/backup
    echo "root_db: T@jneH@slo123!" > /home/admin/backup/hasla.txt
    echo "ssh_prod: ProdKey2025" >> /home/admin/backup/hasla.txt

    chown -R admin:admin /home/admin
    chmod 644 /home/admin/backup/hasla.txt

    auditctl -w /home/admin/backup/hasla.txt -p rwa -k HONEYTOKEN_TRIGGERED
  EOF
}
