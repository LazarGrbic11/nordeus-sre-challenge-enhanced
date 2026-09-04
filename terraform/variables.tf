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
