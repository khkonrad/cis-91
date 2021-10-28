
variable "credentials_file" { 
  default = "/home/karlheinzkonrad/secrets/cis-91.key" 
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

variable "image" {
  default = "ubuntu-os-cloud/ubuntu-2004-lts"
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

resource "google_compute_network" "dokuwiki" {
  name = "dokuwiki"
}

resource "google_compute_disk" "data" {
  name  = "data"
  type  = "pd-standard"
  physical_block_size_bytes = 4096
}


resource "google_storage_bucket" "backup" {
  name          = "dokuwiki-backup-khk"
  force_destroy = true
  
  lifecycle_rule {
    condition {
      age = 2555
    }
    action {
      type = "Delete"
    }
  }
}


resource "google_compute_instance" "dokuwiki" {
  name         = "dokuwiki"
  machine_type = var.instance
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  attached_disk {
    source = "data"
  }


  network_interface {
    network = google_compute_network.dokuwiki.name
    access_config {
    }
  }

    service_account {
    email  = google_service_account.backup-user.email
    scopes = ["cloud-platform"]
    }

}

resource "google_compute_firewall" "cloud" {
  name = "cloud"
  network = google_compute_network.dokuwiki.name
  allow {
    protocol = "tcp"
    ports = ["22","80"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_service_account" "backup-user" {
  account_id   = "backup-user"
  display_name = "backup-user"
  description = "Service account for project 1"
}

resource "google_project_iam_member" "project_member" {
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.backup-user.email}"
}

output "external-ip" {
  value = google_compute_instance.dokuwiki.network_interface[0].access_config[0].nat_ip
}
