terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  backend "gcs" {
    bucket = "mack-terraform-state-backup"
    prefix = "terraform/state/data-pipelines"
  }
}

provider "google" {
  region = var.region
}

locals {
  all_buckets = [
    "dados-infosiga-pessoas",
    "dados-infosiga-sinistros",
    "dados-infosiga-veiculos",
    "dados_seade_idpm",
    "dados_seade_idpm_grupos",
    "dados-seade-mortalidade",
    "dados-seade-ipvs-entorno"
  ]
}

# --- 1. ARTIFACT REGISTRY (Para armazenar a imagem do Cloud Run) ---
resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = "data-pipelines-repo"
  description   = "Repositório para imagens Docker dos pipelines de dados"
  format        = "DOCKER"
}

# --- 2. SERVICE ACCOUNT & IAM (Acesso aos Buckets) ---
resource "google_service_account" "cloud_run_sa" {
  account_id   = "data-runner-sa"
  display_name = "Service Account para operações de dados no Cloud Run e BigQuery"
}

resource "google_storage_bucket_iam_member" "bucket_permissions" {
  for_each = toset(local.all_buckets)

  bucket = each.value
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# --- 3. CLOUD RUN SERVICE: RAW DATA CREATE ---
resource "google_cloud_run_v2_service" "raw_data_create" {
  name     = "raw-data-create"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.cloud_run_sa.email
    scaling {
      max_instance_count = 1
      min_instance_count = 0
    }
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/data-pipelines-repo/raw-data-create:latest"
      resources { 
        limits = { 
          memory = "2Gi"
          cpu = "1000m" 
        } 
      }
    }
  }
}
