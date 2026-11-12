# 1. Criação da Service Account para o Workflow
resource "google_service_account" "workflow_sa" {
  account_id   = "data-workflow-sa"
  display_name = "Service Account para o Google Cloud Workflows"
}

# Concede permissão para a Service Account do Workflow chamar a API do Dataform
resource "google_project_iam_member" "workflow_dataform_invoker" {
  project = var.project_id
  role    = "roles/dataform.editor" # Permite compilar e disparar execuções no Dataform
  member  = "serviceAccount:${google_service_account.workflow_sa.email}"
}

# Service Account dedicada para o Eventarc conseguir disparar o Workflow
resource "google_service_account" "eventarc_sa" {
  account_id   = "eventarc-workflow-sa"
  display_name = "Service Account para o Eventarc disparar o Workflow"
}

# Concede permissão para o Eventarc invocar o Cloud Workflow
resource "google_project_iam_member" "eventarc_workflow_invoker" {
  project = var.project_id
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.eventarc_sa.email}"
}

# 2. Definição do Cloud Workflow (Orientado a Eventos para o Dataform)
resource "google_workflows_workflow" "dataform_orchestrator" {
  name            = "dataform-veiculos-orchestrator"
  region          = var.region
  description     = "Orquestrador acionado por evento do GCS para rodar a tag load_files do Dataform"
  service_account = google_service_account.workflow_sa.id

  source_contents = <<-EOF
    main:
      params: [event]
      steps:
        - log_chegada:
            call: sys.log
            args:
                text: ${ "Evento GCS recebido para o arquivo: " + event.data.name }
                level: INFO

        - filtrar_arquivo:
            switch:
                - condition: ${ event.data.name == "veiculos_2025-2026.csv" }
                  next: criar_compilation_result
            other:
                next: arquivo_ignorado

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
                    compilationResult: $${compilation_result_resp.body.name}
                    invocationConfig:
                        includedTags:
                            - "load_files"
                        transitiveDependenciesIncluded: true
            result: invocation_resp

        - sucesso:
            return: ${ "Dataform acionado com sucesso para o arquivo: " + event.data.name }

        - arquivo_ignorado:
            return: ${ "Arquivo ignorado pelas regras do pipeline: " + event.data.name }
  EOF
}

# 3. Gatilho Eventarc escutando finalizações de upload no bucket de veículos
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
