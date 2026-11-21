output "location" {
  description = "Region de Azure donde se despliega el ambiente."
  value       = var.location
}

output "resource_group_name" {
  description = "Grupo de recursos de la aplicacion."
  value       = var.resource_group_name
}

output "key_vault_name" {
  description = "Nombre del Key Vault."
  value       = var.key_vault_name
}

output "state_storage_account" {
  description = "Cuenta de almacenamiento del estado remoto de Terraform."
  value       = var.state_storage_account
}
