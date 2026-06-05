variable "project_id" {
  description = "The ID of the GCP Project"
  type        = string
}

variable "admin_ip" {
  description = "Public IP address of the admin allowed to access the Bastion Host"
  type        = string
}
