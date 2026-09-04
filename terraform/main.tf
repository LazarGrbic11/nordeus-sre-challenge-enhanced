provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "sre_challenge_vpc" {
  name                    = "${var.project_id}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "sre_challenge_subnet" {
  name          = "${var.project_id}-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.sre_challenge_vpc.name
}

resource "google_container_cluster" "sre_challenge_cluster" {
  name     = "${var.project_id}-cluster"
  location = var.region

  network    = google_compute_network.sre_challenge_vpc.id
  subnetwork = google_compute_subnetwork.sre_challenge_subnet.id

  remove_default_node_pool = false
  initial_node_count       = 1

  deletion_protection = false

  node_config {
    service_account = google_service_account.sre_challenge_account.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
      ]
  }
}


