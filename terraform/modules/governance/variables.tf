variable "location" {
  description = "Region de Azure."
  type        = string
}

variable "resource_group_name" {
  description = "Grupo de recursos."
  type        = string
}

variable "resource_group_id" {
  description = "ID completo del grupo de recursos (scope de la policy)."
  type        = string
}

variable "project_name" {
  description = "Prefijo para nombres de recursos."
  type        = string
}

variable "tags" {
  description = "Etiquetas comunes."
  type        = map(string)
  default     = {}
}

variable "vmss_id" {
  description = "ID del VM Scale Set (objetivo de la alerta E5)."
  type        = string
}

variable "alert_email" {
  description = "Correo de notificacion de alertas."
  type        = string
}
