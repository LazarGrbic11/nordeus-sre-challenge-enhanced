resource "google_project_iam_member" "github_actions_cluster_viewer" {
  project = var.project_id
  role    = "roles/container.clusterViewer"
  member  = "serviceAccount:${var.github_actions_sa}"
}

resource "google_project_iam_member" "github_actions_container_developer" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${var.github_actions_sa}"
}

resource "google_artifact_registry_repository_iam_member" "github_actions_writer" {
  project    = var.project_id
  location   = var.region
  repository = "sre-challenge-images"
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${var.github_actions_sa}"
}