# Load Balancer Standard. Frontend publico para llegar a la app; los VMs del
# VMSS tienen solo IP privada (S2: ninguna VM con IP publica).
resource "azurerm_public_ip" "lb" {
  name                = "${var.project_name}-pip-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_lb" "this" {
  name                = "${var.project_name}-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                 = "frontend"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "this" {
  loadbalancer_id = azurerm_lb.this.id
  name            = "backend"
}

# E2: sonda de salud sobre endpoint dedicado /health
resource "azurerm_lb_probe" "this" {
  name                = "health"
  loadbalancer_id     = azurerm_lb.this.id
  protocol            = "Http"
  port                = 8080
  request_path        = "/health"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "http" {
  name                           = "http"
  loadbalancer_id                = azurerm_lb.this.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 8080
  frontend_ip_configuration_name = "frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.this.id]
  probe_id                       = azurerm_lb_probe.this.id
  floating_ip_enabled            = false
  idle_timeout_in_minutes        = 4
}

# VM Scale Set multi-zona. Ninguna IP publica en las NIC (S2).
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  #checkov:skip=CKV_AZURE_97: cifrado en host no requerido en lab sin datos sensibles locales; discos cifrados en reposo por Azure (riesgo aceptado)
  name                = "${var.project_name}-vmss"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.vm_size
  instances           = var.instance_default
  health_probe_id     = azurerm_lb_probe.this.id # E4: requerido por automatic_instance_repair
  admin_username      = var.admin_username
  upgrade_mode        = "Automatic" # E4: reparacion automatica de instancias
  zones               = var.zones
  custom_data         = base64encode(var.cloud_init) # D3: arranque automatico sin pasos manuales
  tags                = var.tags

  network_interface {
    name    = "nic"
    primary = true

    ip_configuration {
      name      = "ipconfig"
      primary   = true
      subnet_id = var.subnet_id
      # sin public_ip_address_id a propósito (S2)
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.this.id]
    }
  }

  # E4: reparacion automatica de instancias
  automatic_instance_repair {
    enabled      = true
    grace_period = "PT30M"
  }

  # Azure inyecta estos valores por defecto; declararlos evita un diff perpetuo.
  rolling_upgrade_policy {
    cross_zone_upgrades_enabled             = false
    max_batch_instance_percent              = 20
    max_unhealthy_instance_percent          = 20
    max_unhealthy_upgraded_instance_percent = 20
    maximum_surge_instances_enabled         = false
    pause_time_between_batches              = "PT0S"
    prioritize_unhealthy_instances_enabled  = false
  }

  automatic_os_upgrade_policy {
    automatic_os_upgrade_enabled = true
    automatic_rollback_enabled   = false
  }

  # E3: el autoscale gestiona la capacidad; Terraform no toca 'instances'
  lifecycle {
    ignore_changes = [instances]
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  disable_password_authentication = true

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  # S3/S4: identidad administrada SystemAssigned del VMSS
  identity {
    type = "SystemAssigned"
  }
}

# D3: cloud-init renderizado con los valores del entorno (arranque automatico).
locals {
  app_script = indent(6, file("${path.module}/files/app.py"))
  cloud_init = templatefile("${path.module}/files/cloud-init.tftpl", {
    key_vault_uri = var.key_vault_uri
    secret_name   = var.secret_name
    app_script    = local.app_script
  })
}

output "cloud_init" {
  value = local.cloud_init
}

# E3: autoscale con histeresis y cooldowns justificados (ver README).
resource "azurerm_monitor_autoscale_setting" "vmss" {
  name                = "${var.project_name}-autoscale"
  location            = var.location
  resource_group_name = var.resource_group_name
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.vmss.id

  notification {
    email {
      custom_emails                         = [var.alert_email]
      send_to_subscription_administrator    = false
      send_to_subscription_co_administrator = false
    }
  }

  profile {
    name = "default"
    capacity {
      default = var.instance_default
      minimum = var.instance_min
      maximum = var.instance_max
    }

    rule {
      metric_trigger {
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        metric_name        = "Percentage CPU"
        metric_namespace   = "Microsoft.Compute/virtualMachineScaleSets"
        statistic          = "Average"
        time_grain         = "PT1M"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = 2
        cooldown  = "PT10M"
      }
    }

    rule {
      metric_trigger {
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        metric_name        = "Percentage CPU"
        metric_namespace   = "Microsoft.Compute/virtualMachineScaleSets"
        statistic          = "Average"
        time_grain         = "PT1M"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT15M"
      }
    }
  }

  depends_on = [azurerm_linux_virtual_machine_scale_set.vmss]
}
