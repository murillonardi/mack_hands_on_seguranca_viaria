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

# --- 1. ARTIFACT REGISTRY (Repositório Docker Compartilhado) ---
resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = "data-pipelines-repo"
  description   = "Repositório para imagens Docker dos pipelines de dados"
  format        = "DOCKER"
}

# --- 2. SERVICE ACCOUNT & IAM (Execução dos Containers) ---
resource "google_service_account" "cloud_run_sa" {
  account_id   = "data-runner-sa"
  display_name = "Service Account unificada para os pipelines no Cloud Run"
}

# Concede permissão de Object Admin em todos os buckets existentes para a Service Account
resource "google_storage_bucket_iam_member" "bucket_permissions" {
  for_each = toset(local.all_buckets)

  bucket = each.value
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# --- 3. CLOUD RUN: INFOSIGA ---
resource "google_cloud_run_v2_service" "infosiga" {
  name     = "infosiga-ingestion"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.cloud_run_sa.email
    scaling {
      max_instance_count = 1
      min_instance_count = 0
    }
    containers {
      image = var.infosiga_image
      resources { limits = { memory = "2Gi", cpu = "1000m" } }
    }
  }
}

# --- 4. CLOUD RUN: SEADE IDPM ---
resource "google_cloud_run_v2_service" "seade_idpm" {
  name     = "seade-idpm-ingestion"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.cloud_run_sa.email
    scaling {
      max_instance_count = 1
      min_instance_count = 0
    }
    containers {
      image = var.seade_idpm_image
      resources { limits = { memory = "1Gi", cpu = "1000m" } }
      env { 
        name = "BUCKET_NAME" 
        value = "dados_seade_idpm" 
      }
    }
  }
}

# --- 5. CLOUD RUN: SEADE IDPM GRUPOS ---
resource "google_cloud_run_v2_service" "seade_idpm_grupos" {
  name     = "seade-idpm-grupos-ingestion"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.cloud_run_sa.email
    scaling {
      max_instance_count = 1
      min_instance_count = 0
    }
    containers {
      image = var.seade_idpm_grupos_image
      resources { limits = { memory = "1Gi", cpu = "1000m" } }
      env { 
        name = "BUCKET_NAME" 
        value = "dados_seade_idpm_grupos" 
      }
    }
  }
}

# --- 6. CLOUD RUN: SEADE MORTALIDADE ---
resource "google_cloud_run_v2_service" "seade_mortalidade" {
  name     = "seade-mortalidade-ingestion"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.cloud_run_sa.email
    scaling {
      max_instance_count = 1
      min_instance_count = 0
    }
    containers {
      image = var.seade_mortalidade_image
      resources { limits = { memory = "1Gi", cpu = "1000m" } }
      env { 
        name = "BUCKET_NAME" 
        value = "dados-seade-mortalidade" 
      }
    }
  }
}

# --- 7. CLOUD RUN: SEADE IPVS ENTORNO ---
resource "google_cloud_run_v2_service" "seade_ipvs_entorno" {
  name     = "seade-ipvs-entorno-ingestion"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.cloud_run_sa.email
    scaling {
      max_instance_count = 1
      min_instance_count = 0
    }
    containers {
      image = var.seade_ipvs_entorno_image
      resources { limits = { memory = "1Gi", cpu = "1000m" } }
      env {  
        name = "BUCKET_NAME" 
        value = "dados-seade-ipvs-entorno" 
      }
    }
  }
}
  }
}
