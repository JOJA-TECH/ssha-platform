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

variable "tags" {
  description = "Etiquetas comunes."
  type        = map(string)
  default     = {}
}

variable "subnet_id" {
  description = "ID de la subred de app (service endpoint Microsoft.KeyVault)."
  type        = string
}

variable "tenant_id" {
  description = "ID del tenant de Azure AD."
  type        = string
}

variable "operator_ip" {
  description = "IP publica del operador permitida en el firewall del KV."
  type        = string
}

variable "key_vault_name" {
  description = "Nombre del Key Vault (globalmente unico)."
  type        = string
}

variable "secret_name" {
  description = "Nombre del secreto de la aplicacion."
  type        = string
  default     = "app-secret"
}

variable "secret_value" {
  description = "Valor del secreto (sensible; solo en tfvars/secrets, nunca en Git)."
  type        = string
  sensitive   = true
}

variable "secret_expiration_date" {
  description = "Fecha de expiracion del secreto (S3)."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "ID del workspace de Log Analytics para diagnosticos (S6)."
  type        = string
}
