output "virtual_network_id" {
  value = azurerm_virtual_network.this.id
}

output "subnet_app_id" {
  value = azurerm_subnet.app.id
}

output "subnet_app_address_prefix" {
  value = azurerm_subnet.app.address_prefixes[0]
}

output "nsg_app_id" {
  value = azurerm_network_security_group.app.id
}
