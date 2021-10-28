
variable "credentials_file" { 
  default = "../secrets/cis-91.key" 
}

variable "project" {
  default = "cabrillo-cis91"
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-c"
}

variable "instance" {
  default = "e2-micro"
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)
  region  = var.region
  zone    = var.zone 
  project = var.project
}

resource "google_compute_network" "vpc_network" {
  name = "docuwiki-network"
}

resource "google_compute_instance" "vm_instance" {
  name         = "dokuwiki"
  machine_type = var.instance
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }

    service_account {
    email  = google_service_account.proj1-service-account.email
    scopes = ["cloud-platform"]
    }

}

resource "google_compute_firewall" "default-firewall" {
  name = "default-firewall"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports = ["22","80"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_service_account" "proj1-service-account" {
  account_id   = "proj1-service-account"
  display_name = "proj1-service-account"
  description = "Service account for project 1"
}

resource "google_project_iam_member" "project_member" {
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.proj1-service-account.email}"
}

output "external-ip" {
  value = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}
