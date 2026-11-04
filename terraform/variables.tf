variable "project_id" {
  type        = string
  description = "ID do projeto na GCP"
}

variable "region" {
  type        = string
  description = "Região padrão dos recursos"
  default     = "southamerica-east1"
}

variable "container_image" {
  type        = string
  description = "Caminho completo da imagem Docker no Artifact Registry"
}
