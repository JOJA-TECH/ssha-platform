variable "location" {
  description = "Region de Azure donde se desplegan los recursos."
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Nombre del grupo de recursos de la aplicacion."
  type        = string
  default     = "rg-caribeshop-prod"
}

variable "project_name" {
  description = "Nombre corto del proyecto, usado en nombres y etiquetas."
  type        = string
  default     = "caribeshop"
}

variable "state_resource_group" {
  description = "Grupo de recursos que alberga la cuenta de almacenamiento del estado remoto."
  type        = string
  default     = "rg-tfstate"
}

variable "state_storage_account" {
  description = "Cuenta de almacenamiento para el estado remoto de Terraform."
  type        = string
  default     = null
}

variable "state_container" {
  description = "Contenedor de blobs para el estado remoto."
  type        = string
  default     = "tfstate"
}

variable "vm_size" {
  description = "Tamano de las instancias del VM Scale Set."
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Nombre de usuario administrador de las VM."
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "Llave SSH publica para acceso a las VM (solo por la red privada)."
  type        = string
}

variable "instance_min" {
  description = "Numero minimo de instancias del VM Scale Set."
  type        = number
  default     = 2
}

variable "instance_max" {
  description = "Numero maximo de instancias del VM Scale Set."
  type        = number
  default     = 4
}

variable "instance_default" {
  description = "Numero por defecto de instancias del VM Scale Set."
  type        = number
  default     = 2
}

variable "operator_ip" {
  description = "IP publica del operador, permitida en el firewall de Key Vault."
  type        = string
}

variable "zones" {
  description = "Zonas de disponibilidad del VMSS (E1)."
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "secret_value" {
  description = "Valor del secreto de la app (sensible; solo en tfvars/secrets)."
  type        = string
  sensitive   = true
}

variable "secret_expiration_date" {
  description = "Fecha de expiracion del secreto (S3)."
  type        = string
}

variable "alert_email" {
  description = "Correo de notificacion de alertas de Azure Monitor."
  type        = string
}

variable "key_vault_name" {
  description = "Nombre del Key Vault (debe ser globalmente unico)."
  type        = string
}

variable "secret_name" {
  description = "Nombre del secreto de la aplicacion en Key Vault."
  type        = string
  default     = "app-secret"
}

variable "common_tags" {
  description = "Etiquetas aplicadas a todos los recursos."
  type        = map(string)
  default = {
    project = "caribeshop"
    env     = "prod"
  }
}
