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
  description = "ID de la subred de aplicacion (sin IP publica en las NIC)."
  type        = string
}

variable "zones" {
  description = "Zonas de disponibilidad del VMSS (E1)."
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "vm_size" {
  description = "Tamano de instancia del VMSS."
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Usuario administrador de las VM."
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "Llave SSH publica (acceso solo por red privada)."
  type        = string
}

variable "instance_min" {
  description = "Instancias minimas del VMSS."
  type        = number
  default     = 2
}

variable "instance_max" {
  description = "Instancias maximas del VMSS."
  type        = number
  default     = 4
}

variable "instance_default" {
  description = "Instancias por defecto del VMSS."
  type        = number
  default     = 2
}

variable "key_vault_uri" {
  description = "URI del Key Vault (se pasa a la app via cloud-init)."
  type        = string
}

variable "key_vault_id" {
  description = "ID del Key Vault (referencia solo)."
  type        = string
}

variable "secret_name" {
  description = "Nombre del secreto en Key Vault."
  type        = string
  default     = "app-secret"
}

variable "alert_email" {
  description = "Correo de notificaciones de autoscale/alertas."
  type        = string
}

variable "cloud_init" {
  description = "Contenido de cloud-init renderizado (D3: arranque automatico)."
  type        = string
}
