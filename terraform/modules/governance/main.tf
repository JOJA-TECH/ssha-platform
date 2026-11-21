# Workspace de Log Analytics: diagnosticos de Key Vault (S6) y metricas.
resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.project_name}-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# S5: Azure Policy con efecto Deny asignada al grupo de recursos.
# Deniega NIC con direccion IP publica (evita romper S2 por error).
resource "azurerm_policy_definition" "deny_nic_public_ip" {
  name         = "deny-nic-public-ip"
  policy_type  = "Custom"
  display_name = "Deny public IP on network interfaces"
  description  = "Deniega la creacion de interfaces de red con IP publica."
  mode         = "Indexed"
  metadata     = jsonencode({ category = "Network" })
  policy_rule = jsonencode({
    "if" = {
      "allOf" = [
        { "field" = "type", "equals" = "Microsoft.Network/networkInterfaces" },
        {
          "field"  = "Microsoft.Network/networkInterfaces/ipConfigurations[*].publicIpAddress.id",
          "exists" = true
        }
      ]
    },
    "then" = { "effect" = "Deny" }
  })
}

# En azurerm 5.x el recurso se llama azurerm_resource_group_policy_assignment
resource "azurerm_resource_group_policy_assignment" "deny_nic_public_ip" {
  name                 = "deny-nic-public-ip"
  display_name         = "Deny public IP on NICs"
  resource_group_id    = var.resource_group_id
  policy_definition_id = azurerm_policy_definition.deny_nic_public_ip.id
  enforce              = true
}

# E5: grupo de accion con notificacion por correo
resource "azurerm_monitor_action_group" "alert_email" {
  name                = "ag-caribeshop-alert"
  short_name          = "cbalert"
  resource_group_name = var.resource_group_name
  location            = "global"

  email_receiver {
    name          = "operador"
    email_address = var.alert_email
  }
}

# E5: alerta de CPU sostenida sobre el VMSS
resource "azurerm_monitor_metric_alert" "cpu_sostenido" {
  name                = "cpu-sostenido-vmss"
  resource_group_name = var.resource_group_name
  scopes              = [var.vmss_id]
  description         = "CPU sostenida alta en el VMSS (E5)"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.alert_email.id
  }
}
