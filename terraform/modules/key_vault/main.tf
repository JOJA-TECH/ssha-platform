resource "azurerm_key_vault" "this" {
  name                          = var.key_vault_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  enabled_for_disk_encryption   = false
  rbac_authorization_enabled    = true # S3/S4: control de acceso por RBAC (required en azurerm 5.x)
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  purge_protection_enabled      = true # S3: protección contra purgado
  soft_delete_retention_days    = 90   # S3: soft delete
  public_network_access_enabled = false

  tags = var.tags

  # S3: firewall: solo la subred de app (service endpoint) + IP del operador
  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    ip_rules                   = [var.operator_ip]
    virtual_network_subnet_ids = [var.subnet_id]
  }
}

# S3: secreto con fecha de expiracion
resource "azurerm_key_vault_secret" "app" {
  name            = var.secret_name
  key_vault_id    = azurerm_key_vault.this.id
  value           = var.secret_value
  expiration_date = var.secret_expiration_date
}

# S6: diagnostic settings del Key Vault hacia Log Analytics.
resource "azurerm_monitor_diagnostic_setting" "kv" {
  name                       = "kv-to-loganalytics"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
