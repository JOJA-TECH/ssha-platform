output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.this.id
}

output "policy_assignment_id" {
  value = azurerm_resource_group_policy_assignment.deny_nic_public_ip.id
}
