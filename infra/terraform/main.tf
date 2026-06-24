# Minimal Terraform skeleton for the Faith Journal API on GCP.
# Provisions: Artifact Registry, Cloud Run, Secret Manager refs. (Stub — fill in project vars.)

terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.0" }
  }
}

variable "project_id" {}
variable "region" { default = "us-central1" }

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_cloud_run_v2_service" "api" {
  name     = "faith-journal-api"
  location = var.region
  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/faith-journal/api:latest"
      ports { container_port = 8080 }
      env {
        name  = "AI_PROVIDER"
        value = "gemini"
      }
    }
  }
}
