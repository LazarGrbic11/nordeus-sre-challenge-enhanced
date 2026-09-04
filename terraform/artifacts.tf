resource "google_project_service" "artifact_registry_api" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "sre_challenge_repo" {
  depends_on = [google_project_service.artifact_registry_api]

  location      = var.region
  repository_id = "sre-challenge-images"
  description   = "Private Docker repository for Nordeus SRE challenge"
  format        = "DOCKER"

  labels = {
    environment = "production"
  }
}

resource "google_service_account" "sre_challenge_account" {
  account_id   = "sre-challenge-account"
  display_name = "Node Service Account"
}

resource "google_project_iam_member" "sre_challenge_artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.sre_challenge_account.email}"
}