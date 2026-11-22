# Registro de entorno Azure previo al despliegue

Fecha: 2026-11-22 (UTC). Suscripción: `Azure for Students` (`b1759cca-****-****-****-b9ad9454f0d1`), ahora default.
Usuario: jesm****@utb.edu.co. Rol: Owner (ámbito suscripción).
Todos los valores sensibles están enmascarados u omitidos.

## 1. Identidad y permisos

```
az account show
  name           : "Azure for Students"
  id             : b1759cca-****-****-****-b9ad9454f0d1
  state          : Enabled
  tenantId       : ea649e50-****-****-****-2fcffe16fd41
  user           : jesm****@utb.edu.co (tipo: user)
az role assignment list --scope /subscriptions/b1759cca-... --assignee jesm****@utb.edu.co
  Contributor
  User Access Administrator
  Owner
```

Conclusión: **Owner** → permisos suficientes para role assignments (S4), policy assignments (S5) y escritura de estado remoto en Storage (S1). No hay bloqueo de permisos.

## 2. Proveedores de recursos (registro requerido antes de crear recursos)

Todos `Registered`:

| Proveedor | Estado |
|-----------|--------|
| Microsoft.Authorization | Registered |
| Microsoft.Compute | Registered |
| Microsoft.KeyVault | Registered |
| Microsoft.Network | Registered |
| Microsoft.OperationalInsights | Registered |
| Microsoft.Storage | Registered |
| Microsoft.Insights | Registered |

## 3. Cuotas vCPU — `az vm list-usage -l eastus -o table` (extracto)

| Medida | Uso | Límite |
|--------|-----|--------|
| Total Regional vCPUs | 0 | 6 |
| Standard BS Family vCPUs | 0 | 4 |
| Standard Basv2 Family vCPUs | 0 | 10 |
| Standard Bsv2 Family vCPUs | 0 | 10 |
| Standard Bpsv2 Family vCPUs | 0 | 10 |
| Virtual Machine Scale Sets | 0 | 2500 |

Implicación: con `Standard_B1s` (1 vCPU) cabe scale-out hasta 4 instancias (4 vCPU, límite BS). Con `Standard_B2s` (2 vCPU) no cabe scale-out más allá de 2 instancias.

## 4. Grupos de recursos creados (preflight, sin costo)

| Nombre | Ubicación | Estado | Propósito |
|--------|-----------|--------|-----------|
| rg-caribeshop-prod | eastus | Creado | RG de la aplicación (requerido por `data.azurerm_resource_group.this` en main.tf) |
| rg-tfstate-caribeshop | eastus | Creado | RG del estado remoto de Terraform (backend `azurerm`) |

## 5. Nombre de cuenta de almacenamiento del estado

`az storage account check-name --name tfstatecaribeshop` → `nameAvailable = true` (disponible globalmente).

## 6. Recursos a crear en el despliegue (alcance laboratorio)

VNet, subred snet-app, NSG, IP pública (LB), Load Balancer Standard, VMSS (2× B1s, zonas 1-2-3), Key Vault (RBAC, purge protection, firewall, secreto con expiración), Log Analytics, Azure Policy Deny, Action Group + alerta de métrica, cuenta de almacenamiento backend + contenedor tfstate.

## 7. Costo estimado si se deja en ejecución 24/7

≈ $80–100/mes. Crédito Azure for Students ≈ $100 con límite de gasto. **Destruir tras recoger evidencias (`terraform destroy`) para no agotar el crédito.**

## 8. Siguiente paso

El usuario debe crear localmente `terraform/environments/prod/terraform.tfvars` (gitignorado) con `ssh_public_key`, `operator_ip`, `key_vault_name`, `secret_value`, `secret_expiration_date`, `alert_email` y opcionalmente `vm_size = "Standard_B1s"`. Luego `terraform init`, `terraform plan`, revisión, y `apply` bajo autorización explícita.
