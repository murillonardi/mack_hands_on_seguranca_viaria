output "infosiga_cloud_run_url" {
  value = google_cloud_run_v2_service.infosiga.uri
}

output "seade_cloud_run_url" {
  value = google_cloud_run_v2_service.seade.uri
}

output "seade_idpm_url" {
  value = google_cloud_run_v2_service.seade_idpm.uri
}

output "seade_idpm_grupos_url" {
  value = google_cloud_run_v2_service.seade_idpm_grupos.uri
}

output "seade_mortalidade_url" {
  value = google_cloud_run_v2_service.seade_mortalidade.uri
}

output "seade_ipvs_entorno_url" {
  value = google_cloud_run_v2_service.seade_ipvs_entorno.uri
}

output "artifact_registry_repo" {
  value = google_artifact_registry_repository.repo.id
}
