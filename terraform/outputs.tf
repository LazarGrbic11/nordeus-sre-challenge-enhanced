# The IP address of the Kubernetes API Server (Control Plane)
output "gke_cluster_endpoint" {
  description = "The IP address of the GKE cluster control plane master endpoint."
  value       = google_container_cluster.sre_challenge_cluster.endpoint
}

# The Primary CIDR Block of the Subnet
output "subnet_primary_cidr" {
  description = "The primary IP address range of the GKE subnet."
  value       = google_compute_subnetwork.sre_challenge_subnet.ip_cidr_range
}

output "repository_url" {
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.sre_challenge_repo.repository_id}"
  description = "The URL for the Docker image repository"
}

