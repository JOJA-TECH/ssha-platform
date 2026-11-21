terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-caribeshop"
    storage_account_name = "tfstatecaribeshop"  # sobrescribir con -backend-config (nombre unico global)
    container_name       = "tfstate"
    key                  = "caribeshop/prod/terraform.tfstate"
  }
}
