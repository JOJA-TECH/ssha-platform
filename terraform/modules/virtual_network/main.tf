resource "azurerm_virtual_network" "this" {
  name                = "${var.project_name}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

# Subred de aplicacion con service endpoint para Key Vault (requisito del
# firewall del KV: solo esta subred + IP del operador pueden alcanzarlo).
resource "azurerm_subnet" "app" {
  name                 = "snet-app"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes = ["10.0.1.0/24"]
  # S3: el service endpoint Microsoft.KeyVault se declara en el firewall del
  # Key Vault (azurerm_key_vault.network_acls.virtual_network_subnet_ids),
  # que referencia esta subred por su ID.
}

# S2: NSG de minimo privilegio.
# - Inbound: solo sondeo del balanceador (AzureLoadBalancer) y app (8080) desde
#   la VNet. Todo lo resto denegado (incluido SSH/RDP desde Internet).
# - Outbound: solo Azure Key Vault (443) e IMDS (169.254.169.254:80). Resto
#   denegado (ninguna VM sale a Internet arbitrario).
resource "azurerm_network_security_group" "app" {
  name                = "${var.project_name}-nsg-app"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "AllowHealthProbe"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes    = ["AzureLoadBalancer"]
    destination_address_prefixes = ["*"]
  }

  security_rule {
    name                       = "AllowAppInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefixes    = ["VirtualNetwork"]
    destination_address_prefixes = ["*"]
  }

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes    = ["*"]
    destination_address_prefixes = ["*"]
  }

  security_rule {
    name                       = "AllowAzureKeyVaultOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefixes    = ["*"]
    destination_address_prefixes = ["AzureKeyVault"]
  }

  security_rule {
    name                       = "AllowIMDSOutbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefixes    = ["*"]
    destination_address_prefixes = ["169.254.169.254"]
  }

  security_rule {
    name                       = "DenyAllOutbound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes    = ["*"]
    destination_address_prefixes = ["*"]
  }
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}
