# 1. Criação da Service Account para o Workflow (com permissão de invocar os Cloud Runs)
resource "google_service_account" "workflow_sa" {
  account_id   = "data-workflow-sa"
  display_name = "Service Account para o Google Cloud Workflows"
}

# Concede permissão para o Workflow invocar os serviços do Cloud Run
resource "google_cloud_run_v2_service_iam_member" "workflow_invoker" {
  for_each = {
    infosiga = google_cloud_run_v2_service.infosiga.name
    seade_idpm = google_cloud_run_v2_service.seade_idpm
    seade_idpm_grupos = google_cloud_run_v2_service.seade_idpm_grupos
    seade_mortalidade = google_cloud_run_v2_service.seade_mortalidade
    seade_ipvs_entorno = google_cloud_run_v2_service.seade_ipvs_entorno
  }

  location     = var.region
  project      = var.project_id
  service      = each.value
  role         = "roles/run.invoker"
  member       = "serviceAccount:${google_service_account.workflow_sa.email}"
}

# 2. Definição do Cloud Workflow
resource "google_workflows_workflow" "pipeline_orchestrator" {
  name            = "data-pipelines-orchestrator"
  region          = var.region
  description     = "Orquestrador automatizado dos pipelines de ingestão"
  service_account = google_service_account.workflow_sa.id

  # Você pode escrever o código do workflow direto aqui ou carregar de um arquivo externo (.yaml)
  source_contents = <<EOF
main:
  steps:
    - call_infosiga:
        call: http.post
        args:
          url: "${google_cloud_run_v2_service.infosiga.uri}"
          auth:
            type: OIDC
            audience: "${google_cloud_run_v2_service.infosiga.uri}"
        result: infosiga_result

    - call_seade_idpm:
        call: http.post
        args:
          url: "${google_cloud_run_v2_service.seade_idpm.uri}"
          auth:
            type: OIDC
            audience: "${google_cloud_run_v2_service.seade_idpm.uri}"
        result: seade_idpm_result

    - call_seade_idpm_grupos:
        call: http.post
        args:
          url: "${google_cloud_run_v2_service.seade_idpm_grupos.uri}"
          auth:
            type: OIDC
            audience: "${google_cloud_run_v2_service.seade_idpm_grupos.uri}"
        result: seade_idpm_grupos_result

    - call_seade_mortalidade:
        call: http.post
        args:
          url: "${google_cloud_run_v2_service.seade_mortalidade.uri}"
          auth:
            type: OIDC
            audience: "${google_cloud_run_v2_service.seade_mortalidade.uri}"
        result: seade_mortalidade_result

    - call_seade_ipvs_entorno:
        call: http.post
        args:
          url: "${google_cloud_run_v2_service.seade_ipvs_entorno.uri}"
          auth:
            type: OIDC
            audience: "${google_cloud_run_v2_service.seade_ipvs_entorno.uri}"
        result: seade_ipvs_entorno_result

    - finish:
        return: "Todos os pipelines executados com sucesso!"
EOF
}
