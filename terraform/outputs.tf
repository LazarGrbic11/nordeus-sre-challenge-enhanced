# The IP address of the Kubernetes API Server (Control Plane)
output "gke_cluster_endpoint" {
  description = "The IP address of the GKE cluster control plane master endpoint."
  value       = google_container_cluster.sre_challenge_cluster.endpoint
}

output "repository_url" {
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.sre_challenge_repo.repository_id}"
  description = "The URL for the Docker image repository"
}

