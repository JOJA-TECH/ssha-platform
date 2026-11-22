variable "location" {
  description = "Region de Azure."
  type        = string
}

variable "resource_group_name" {
  description = "Grupo de recursos."
  type        = string
}

variable "project_name" {
  description = "Prefijo para nombres de recursos."
  type        = string
}

variable "operator_ip" {
  description = "CIDR del operador, unico origen externo autorizado a la app (8080)."
  type        = string
}

variable "tags" {
  description = "Etiquetas comunes."
  type        = map(string)
  default     = {}
}
