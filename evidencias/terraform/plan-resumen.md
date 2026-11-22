# Resumen del plan de Terraform (sin aplicar) — CaribeShop lab

> **Documento histórico (superado):** corresponde al intento fallido en `centralus` con una suscripción de estudiante. El despliegue real y su plan final están en `../azure/despliegue-sub1.md`.

Fecha: 2026-11-22 (UTC). Suscripción: `Azure for Students` (`b1759cca-****-****-****-b9ad9454f0d1`).
Región: `centralus` (política `sys.regionrestriction` de la suscripción solo permite brazilsouth, centralus, canadacentral, chilecentral, northcentralus; eastus fue denegada con `RequestDisallowedByAzure`).

## Comandos ejecutados (resultados sanitizados)

```
terraform fmt -check -recursive  -> exit 0 (tras formatear el tfvars local gitignorado)
terraform validate               -> Success! The configuration is valid.
terraform init -reconfigure -backend-config="storage_account_name=tfstatecaribeshop"
  -> OK, backend azurerm, estado: caribeshop/prod/terraform.tfstate
     en rg-tfstate-caribeshop / tfstatecaribeshop / contenedor tfstate
terraform plan -no-color -input=false -out=/tmp/caribeshop.tfplan
  -> Plan: 20 to add, 0 to change, 0 to destroy.
```

## Bug corregido durante el preflight (cambio de archivo del repositorio)

- `terraform/modules/vmss/main.tf` línea 64: `custom_data = var.cloud_init` → `custom_data = base64encode(var.cloud_init)`.
  Motivo: azurerm 5.x exige base64 en `custom_data`; sin esto el plan fallaba con `Error: expected "custom_data" to be a base64 string, got #cloud-config`. Es la mínima corrección necesaria para desplegar.

Otros cambios: ninguno en el código del repositorio. Archivos nuevos: `evidencias/` (inspección, preflight, azure, terraform). `terraform.tfvars` local (gitignorado) con valores de laboratorio generados localmente (secreto aleatorio, nunca mostrado).

## Recursos del plan (20 a crear)

Todos en `rg-caribeshop-prod` (centralus) salvo el backend (ya creado):

| Módulo | Recursos |
|--------|----------|
| virtual_network | 1 VNet, 1 subred (snet-app), 1 NSG, 1 asociación subred-NSG |
| vmss | 1 IP pública, 1 LB, 1 backend pool, 1 sonda /health, 1 regla LB, 1 VMSS (2× B1s, zonas 1-2-3, identidad SystemAssigned, cloud-init base64, reparación automática), 1 autoscale setting |
| key_vault | 1 Key Vault (RBAC, purge protection, firewall), 1 secreto con expiración, 1 diagnostic setting KV→Log Analytics |
| governance | 1 Log Analytics workspace, 1 policy definition Deny, 1 policy assignment al RG, 1 action group email, 1 alerta de métrica CPU |
| root | 1 role assignment (Key Vault Secrets User → identidad VMSS) |

## Verificación de seguridad del plan

- `0 to destroy`: sin destrucciones inesperadas.
- Sin recursos fuera del RG objetivo (todos `resource_group_name = rg-caribeshop-prod`, `location = centralus`).
- Sin IP pública en NICs del VMSS (solo la IP pública del LB, necesaria como entrada).
- Sin valores sensibles en el output del plan: `secret_value` es `sensitive`, no se imprimió. El KV name y la IP de operator aparecen (no son secretos).
- Costo estimado: ~$80–100/mes si se deja en ejecución 24/7 (crédito de estudiante ~$100). **Requiere destrucción posterior.**

## Estado

Plan guardado en `/tmp/caribeshop.tfplan` (fuera del repositorio). Pendiente: **autorización explícita de `apply`** y ejecución de pruebas P1/P2/P3.
