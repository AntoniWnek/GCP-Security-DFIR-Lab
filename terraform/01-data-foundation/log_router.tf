# THE PIPELINE: Cloud Logging Sink
resource "google_logging_project_sink" "dfir_log_sink" {
  name        = "dfir-bigquery-sink"
  
  # Destination: The BigQuery dataset created in main.tf
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.soc_telemetry.dataset_id}"

  # Filter: Only want network traffic (VPC Flows) and OS-level logs (Auditd/Syslog)
  filter      = "resource.type=\"gce_subnetwork\" OR resource.type=\"gce_instance\""

  # Crucial for security: Creates a unique Service Account just for this pipeline
  unique_writer_identity = true
}

# THE PERMISSION: Granting the pipeline access to write to BigQuery
resource "google_project_iam_binding" "log_sink_bq_writer" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"

  members = [
    google_logging_project_sink.dfir_log_sink.writer_identity,
  ]
}
