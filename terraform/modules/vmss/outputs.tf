output "vmss_id" {
  value = azurerm_linux_virtual_machine_scale_set.vmss.id
}

output "vmss_name" {
  value = azurerm_linux_virtual_machine_scale_set.vmss.name
}

output "principal_id" {
  description = "ID de entidad de servicio de la identidad administrada del VMSS (S4)."
  value       = azurerm_linux_virtual_machine_scale_set.vmss.identity[0].principal_id
}

output "lb_public_ip" {
  value = azurerm_public_ip.lb.ip_address
}

output "backend_address_pool_id" {
  value = azurerm_lb_backend_address_pool.this.id
}
