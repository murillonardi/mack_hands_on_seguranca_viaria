# --- 1. CLOUD RUN DO INFOSIGA ---
resource "google_cloud_run_v2_service" "infosiga" {
  name     = "infosiga-ingestion"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.cloud_run_sa.email
    containers {
      image = var.infosiga_image
      resources {
        limits = { memory = "2Gi", cpu = "1000m" }
      }
    }
  }
}

# --- 2. CLOUD RUN DO SEADE IPVS ---
resource "google_cloud_run_v2_service" "seade" {
  name     = "seade-ipvs-ingestion"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.cloud_run_sa.email
    containers {
      image = var.seade_image
      resources {
        limits = { memory = "1Gi", cpu = "1000m" } // Ajuste o recurso conforme a necessidade do SEADE
      }
    }
  }
}

# --- 3. SCHEDULERS INDEPENDENTES ---
resource "google_cloud_scheduler_job" "seade_trigger" {
  name        = "seade-ipvs-monthly-trigger"
  region      = var.region
  schedule    = "0 7 * * 1-5"
  time_zone   = "America/Sao_Paulo"

  http_target {
    http_method = "POST"
    uri         = google_cloud_run_v2_service.seade.uri
    oidc_token {
      service_account_email = google_service_account.scheduler_sa.email
      audience              = google_cloud_run_v2_service.seade.uri
    }
  }
}
