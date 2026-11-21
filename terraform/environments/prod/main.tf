locals {
  common_tags = var.common_tags
}

# Datos de suscripcion / grupo de recursos (para scope de policy y rol).
data "azurerm_subscription" "current" {}
data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

# --- Red (S2) ---
module "virtual_network" {
  source = "../../modules/virtual_network"
  location            = var.location
  resource_group_name = var.resource_group_name
  project_name        = var.project_name
  tags                = local.common_tags
}

# --- Key Vault (S3, S4, S6) ---
module "key_vault" {
  source = "../../modules/key_vault"
  location                     = var.location
  resource_group_name          = var.resource_group_name
  project_name                 = var.project_name
  tags                         = local.common_tags
  subnet_id                    = module.virtual_network.subnet_app_id
  tenant_id                    = data.azurerm_subscription.current.tenant_id
  operator_ip                  = var.operator_ip
  key_vault_name               = var.key_vault_name
  secret_name                  = var.secret_name
  secret_value                 = var.secret_value
  secret_expiration_date       = var.secret_expiration_date
  log_analytics_workspace_id   = module.governance.log_analytics_workspace_id
}

# --- VM Scale Set + Load Balancer + autoscale (E1-E4, D3) ---
module "vmss" {
  source = "../../modules/vmss"
  location             = var.location
  resource_group_name  = var.resource_group_name
  project_name         = var.project_name
  tags                 = local.common_tags
  subnet_id            = module.virtual_network.subnet_app_id
  zones                = var.zones
  vm_size              = var.vm_size
  admin_username       = var.admin_username
  ssh_public_key       = var.ssh_public_key
  instance_min         = var.instance_min
  instance_max         = var.instance_max
  instance_default     = var.instance_default
  key_vault_uri        = module.key_vault.key_vault_uri
  key_vault_id         = module.key_vault.key_vault_id
  secret_name          = var.secret_name
  alert_email          = var.alert_email
  cloud_init           = module.vmss.cloud_init
}

# --- Gobierno y observabilidad (S5, E5) ---
module "governance" {
  source = "../../modules/governance"
  location            = var.location
  resource_group_name = var.resource_group_name
  resource_group_id   = data.azurerm_resource_group.this.id
  project_name        = var.project_name
  tags                = local.common_tags
  vmss_id             = module.vmss.vmss_id
  alert_email         = var.alert_email
}

# S4: la identidad del VMSS SOLO puede leer secretos del Key Vault
# (minimo privilegio, rol Key Vault Secrets User). Se define aquí para romper
# la dependencia circular key_vault <-> vmss.
data "azurerm_role_definition" "kv_secrets_user" {
  name               = "Key Vault Secrets User"
  scope              = data.azurerm_subscription.current.id
}

resource "azurerm_role_assignment" "vmss_kv_secrets_reader" {
  scope                = module.key_vault.key_vault_id
  role_definition_id   = data.azurerm_role_definition.kv_secrets_user.id
  principal_id         = module.vmss.principal_id
}
