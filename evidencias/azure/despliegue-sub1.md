# Despliegue y verificación en Azure subscription 1 — CaribeShop

Fecha: 2026-11-22 (UTC). Todos los identificadores de cuenta, IP y OID están enmascarados. El valor del secreto **nunca** se imprimió ni se guardó en evidencias.

## 1. Suscripción y permisos

| Concepto | Valor (sanitizado) |
|----------|--------------------|
| Suscripción | `Azure subscription 1` — `9490c340-…‑0fa8ad71c767` |
| Tenant | `25f92c31-…‑1442bfbadaa6` |
| Usuario | `y***@hotmail.com`, rol **Owner** |
| Región | `eastus` (zonas 1, 2, 3 disponibles) |
| Restricción regional | Ninguna |

Las dos suscripciones "Azure for Students" quedaron descartadas: capacidad agotada en las cinco regiones permitidas, para todos los SKU probados (`SkuNotAvailable — Capacity Restrictions`). Ver `bloqueo-compute-suscripcion.md` y `bloqueo-sku-centralus.md`. Los labs parciales de esas suscripciones y los RG `capcheck*` temporales fueron eliminados con autorización explícita.

## 2. SKU y cuota (decisión)

No existen SKU "free" para VM/VMSS en Azure (el tier Free es de App Service/Functions). La API `az vm list-skus -l eastus --resource-type virtualMachines` listó 836 SKU de pago sin restricción declarada; en la práctica:

| SKU | Resultado de creación real en `eastus` |
|-----|------------------------------------------|
| `Standard_B1ls`, `Standard_B1ms`, `Standard_B2s_v2`, `Standard_B1s`, `Standard_A0`, `Basic_A0` | `SkuNotAvailable — Capacity Restrictions` |
| `Standard_A0`, `Standard_D2a_v4`, `Standard_F2s_v2` | `QuotaExceeded` |
| **`Standard_D2as_v4`** | **OK** |
| `Standard_E2as_v4` | OK |

La cuota regional es de **4 vCPU**. Con `D2as_v4` (2 vCPU) caben exactamente 2 instancias: se configuró `instance_min = instance_default = instance_max = 2`. No hay margen para scale-out automático (ver limitación en P1).

## 3. Backend remoto (S1)

| Concepto | Valor (sanitizado) |
|----------|--------------------|
| RG del estado | `rg-tfstate-caribeshop` |
| Cuenta de almacenamiento | `tfstatecshop********` |
| Contenedor / clave | `tfstate` / `caribeshop/prod/terraform.tfstate` |

Creado con `scripts/bootstrap-backend.sh`; `terraform init -reconfigure -backend-config=storage_account_name=…`. Ningún estado versionado en Git.

## 4. Apply y resultado

- `terraform fmt -check -recursive`: exit 0.
- `terraform validate`: Success.
- `terraform plan` inicial: **20 to add, 0 to change, 0 to destroy**.
- `terraform apply`: **20 recursos creados**, sin cambios ni destrucciones fuera del alcance.
- Correcciones posteriores aplicadas vía Terraform (cada una con plan revisado): regla NSG para el IP del operador (3 add / 1 change / 3 destroy), corrección de indentación del cloud-init (2 reemplazos del VMSS), eliminación de `owner:`/`package_update` que fallaban por egreso cerrado, y declaración explícita de `rolling_upgrade_policy` para eliminar un diff perpetuo del provider.
- **Plan final**: `No changes. Your infrastructure matches the configuration.` (`terraform plan -detailed-exitcode` → 0).

## 5. Estado verificado en Azure

| Recurso | Verificación |
|---------|--------------|
| VMSS `caribeshop-vmss` | `Standard_D2as_v4`, `zones = [1,2]`, capacidad 2, modo `Automatic` |
| Instancia 1 | Zona 1 (confirmada por IMDS), `provisioningState = Succeeded` |
| Instancia 2 | Zona 2 (confirmada por IMDS), `provisioningState = Succeeded` |
| Load Balancer | IP pública `172.172.182.***`, sonda HTTP `/health:p8080` |
| NIC del VMSS | Sin IP pública (confirmado: listado vacío) |
| Key Vault | `kv-cshop-sub1-********`, RBAC, purge protection, soft-delete 90 días, `publicNetworkAccess = Enabled` con firewall `defaultAction = Deny` + subred de app + IP operador |
| Secreto `app-secret` | Habilitado, expira `2027-12-31T23:59:59+00:00`; solo se leyó su ID y expiración |
| Autoscale | Perfil 2/2/2 (restaurado tras P1.1); reglas CPU >70 % / <30 %, cooldowns 10/15 min |
| Policy S5 | `deny-nic-public-ip` asignada y `enforce = true` |
| App | `/health` → 200 `ok`; `/` → 200; `/secret` → 200 `len=48 sha256=7eb1c3fa22fb1a8e` (huella, nunca el valor) |

## 6. Limitaciones conocidas

- **P1.3 no demostrable**: la cuota de 4 vCPU impide escalar de 2 a 3/4 instancias. Sólo se hizo escalado manual 1→2 (reversible, durante P1.1) y se restauró a 2/2/2.
- **E3 sin historial**: la API `autoscaleSettings/…/runHistory?api-version=2022-10-01` responde `Bad Request: Unrecognized operationName: runHistory`; la configuración sí existe y se verificó con `az monitor autoscale show`.
- **E4/E5**: reparación automática y alerta de correo están configuradas en código, pero no se observó reemplazo automático ni correo recibido durante el lab.
- El laboratorio sigue **en ejecución y generando costo**; no hay autorización para `terraform destroy`.
