# 1. Criação da Service Account para o Workflow
resource "google_service_account" "workflow_sa" {
  account_id   = "data-workflow-sa"
  display_name = "Service Account para o Google Cloud Workflows"
}

# Concede permissão para o Workflow invocar o Cloud Run (raw-data-create)
resource "google_cloud_run_v2_service_iam_member" "workflow_run_invoker" {
  location = var.region
  project  = var.project_id
  name     = google_cloud_run_v2_service.raw_data_create.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.workflow_sa.email}"
}

# Service Account dedicada para o Eventarc disparar o Workflow
resource "google_service_account" "eventarc_sa" {
  account_id   = "eventarc-workflow-sa"
  display_name = "Service Account para o Eventarc disparar o Workflow"
}

# 2. Definição do Cloud Workflow (Orquestra Cloud Run + Dataform)
resource "google_workflows_workflow" "dataform_orchestrator" {
  name            = "dataform-veiculos-orchestrator"
  region          = var.region
  description     = "Orquestrador acionado por evento do GCS: atualiza raw tables via Cloud Run e dispara tag load_files no Dataform"
  service_account = google_service_account.workflow_sa.id

  source_contents = <<-EOF
    main:
      params: [event]
      steps:
        - log_chegada:
            call: sys.log
            args:
                text: '$${("Evento GCS recebido para o arquivo: " + event.data.name)}'

        - filtrar_arquivo:
            switch:
                - condition: '$${event.data.name == "veiculos_2025-2026.csv"}'
                  next: chamar_cloud_run_ingestao
                - condition: true
                  next: arquivo_ignorado

        - chamar_cloud_run_ingestao:
            call: http.post
            args:
                url: "${google_cloud_run_v2_service.raw_data_create.uri}"
                auth:
                    type: OIDC
                    audience: "${google_cloud_run_v2_service.raw_data_create.uri}"
                timeout: 960
            result: cloud_run_resp

        - criar_compilation_result:
            call: http.post
            args:
                url: https://dataform.googleapis.com/v1beta1/projects/${var.project_id}/locations/${var.region}/repositories/dataform-pipeline/compilationResults
                auth:
                    type: OAuth2
                body:
                    gitCommitish: "main"
            result: compilation_result_resp

        - disparar_workflow_invocation:
            call: http.post
            args:
                url: https://dataform.googleapis.com/v1beta1/projects/${var.project_id}/locations/${var.region}/repositories/dataform-pipeline/workflowInvocations
                auth:
                    type: OAuth2
                body:
                    compilationResult: '$${compilation_result_resp.body.name}'
                    invocationConfig:
                        includedTags:
                            - "load_files"
                        transitiveDependenciesIncluded: true
            result: invocation_resp

        - sucesso:
            return: '$${("Pipeline executado com sucesso para o arquivo: " + event.data.name)}'

        - arquivo_ignorado:
            return: '$${("Arquivo ignorado pelas regras do pipeline: " + event.data.name)}'
  EOF
}

# 3. Gatilho Eventarc escutando finalizações no bucket de veículos
resource "google_eventarc_trigger" "gcs_to_workflow_trigger" {
  name     = "trigger-veiculos-dataform"
  location = var.region
  project  = var.project_id

  matching_criteria {
    attribute = "type.googleapis.com"
    value     = "google.cloud.storage.object.v1.finalized"
  }

  matching_criteria {
    attribute = "bucket"
    value     = "dados-infosiga-veiculos"
  }

  destination {
    workflow = google_workflows_workflow.dataform_orchestrator.id
  }

  service_account = google_service_account.eventarc_sa.email
}
