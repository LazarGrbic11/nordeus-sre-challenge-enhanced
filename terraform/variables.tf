variable "project_id" {
  description = "Nordeus SRE challenge"
  type        = string
  default     = "nordeus-sre-challenge"
}

variable "region" {
  description = "The GCP region to deploy resources"
  type        = string
  default     = "europe-central2"
}

variable "github_actions_sa" {
  description = "Service account for GitHub Actions deployment"
  type        = string
  default     = "github-actions@nordeus-sre-challenge.iam.gserviceaccount.com"
}