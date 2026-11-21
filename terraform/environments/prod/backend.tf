terraform {
  backend "azurerm" {
    resource_group_name  = var.state_resource_group
    storage_account_name = var.state_storage_account
    container_name       = var.state_container
    key                  = "caribeshop/prod/terraform.tfstate"
  }
}
