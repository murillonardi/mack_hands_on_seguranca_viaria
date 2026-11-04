output "cloud_run_url" {
  value       = google_cloud_run_v2_service.pipeline.uri
  description = "URL do serviço Cloud Run implantado"
}

output "artifact_registry_repo" {
  value       = google_artifact_registry_repository.repo.id
  description = "ID do repositório no Artifact Registry"
}
