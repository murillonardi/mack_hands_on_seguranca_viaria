locals {
  buckets = [
    "dados-infosiga-pessoas",
    "dados-infosiga-sinistros",
    "dados-infosiga-veiculos",
    "dados-seade-ipvs"
  ]
}

#Criação do Artifact Registry
resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = "data-pipelines-repo"
  description   = "Repositório para imagens Docker dos pipelines de dados"
  format        = "DOCKER"
}

resource "google_service_account" "cloud_run_sa" {
  account_id   = "38933711443-compute"
  display_name = "Service Account para Ingestão dos Arquivos via Functions do Cloud Run"
}

# Concede permissão de escrita (Object Admin) nos 3 buckets para a Service Account
resource "google_storage_bucket_iam_member" "bucket_permissions" {
  for_each = toset(local.buckets)

  bucket = google_storage_bucket.infosiga_buckets[each.value].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_cloud_run_v2_service" "infosiga" {
  name     = "infosiga-ingestion"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.cloud_run_sa.email
    containers {
      image = var.infosiga_image
      resources {
        limits = { memory = "0.5Gi", cpu = "1000m" }
      }
    }
  }
}

resource "google_cloud_run_v2_service" "seade" {
  name     = "seade-ipvs-ingestion"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.cloud_run_sa.email
    containers {
      image = var.seade_image
      resources {
        limits = { memory = "0.5Gi", cpu = "1000m" } // Ajuste o recurso conforme a necessidade do SEADE
      }
    }
  }
}

resource "google_service_account" "scheduler_sa" {
  account_id   = "data-scheduler-sa"
  display_name = "Service Account para disparar os Cloud Schedulers"
}

# Permissão para o Scheduler invocar o InfoSiga
resource "google_cloud_run_v2_service_iam_member" "infosiga_invoker" {
  name     = google_cloud_run_v2_service.infosiga.name
  location = google_cloud_run_v2_service.infosiga.location
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.scheduler_sa.email}"
}

# Permissão para o Scheduler invocar o SEADE
resource "google_cloud_run_v2_service_iam_member" "seade_invoker" {
  name     = google_cloud_run_v2_service.seade.name
  location = google_cloud_run_v2_service.seade.location
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.scheduler_sa.email}"
}
