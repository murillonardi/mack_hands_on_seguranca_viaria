variable "project_id" {
  type        = string
  description = "ID do projeto na GCP"
  default     = "project-f1079166-4703-4cc3-975"
}

variable "region" {
  type        = string
  description = "Região padrão"
  default     = "us-central1"
}

variable "infosiga_image" {
  type = string
}

variable "seade_image" {
  type = string
}

variable "seade_idpm_image" {
  type = string
}

variable "seade_idpm_grupos_image" {
  type = string
}

variable "seade_mortalidade_image" {
  type = string
}

variable "seade_ipvs_entorno_image" {
  type = string
}
