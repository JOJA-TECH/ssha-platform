# Resumen previo al despliegue (preflight) — CaribeShop lab

Estado de la puerta de decisión: **SUPERADA**. No hay incumplimiento obligatorio de código, no hay secretos expuestos, y no hay bloqueo de permisos en la segunda suscripción.

## 1. Entorno confirmado (comandos de Azure CLI, valores sensibles enmascarados)

| Concepto | Valor |
|----------|-------|
| Identidad activa | jesm****@utb.edu.co (tipo user) |
| Rol en la suscripción de destino | **Owner** (también Contributor y User Access Administrator) — permisos suficientes para S4 (role assignment), S5 (policy assignment) y S1 backend (escritura de blob de estado) |
| Suscripción de destino | `Azure for Students` — `b1759cca-7ca2-4f3b-98ee-b4702f3a8fcc` (ahora default) |
| Estado | Enabled |
| Tenant | `ea649e50-****-****-****-2fcffe16fd41` (Universidad Tecnológica de Bolívar) |
| Región destino | `eastus` |
| Grupo de recursos de la app | `rg-caribeshop-prod` — **creado** (eastus) |
| Grupo de recursos del estado | `rg-tfstate-caribeshop` — **creado** (eastus) |
| Cuenta de almacenamiento del estado | `tfstatecaribeshop` — nombre disponible (no creada aún) |
| Contenedor de estado | `tfstate` |
| Clave de estado | `caribeshop/prod/terraform.tfstate` |

Proveedores de recursos registrados: Microsoft.Compute, Microsoft.KeyVault, Microsoft.Network, Microsoft.Authorization, Microsoft.OperationalInsights, Microsoft.Storage, Microsoft.Insights (todos `Registered`).

RG ajenos (`cco-lab-rg`, `cco-vm-rg`, `NetworkWatcherRG`) no se tocaron.

## 2. Cuotas (eastus) — `az vm list-usage -l eastus -o table`

| Medida | Uso actual | Límite | Implicación |
|--------|------------|--------|-------------|
| Total Regional vCPUs | 0 | 6 | Suficiente para el lab |
| Standard BS Family vCPUs | 0 | 4 | Con `Standard_B2s` (2 vCPU) solo caben 2 instancias; sin cabeza para scale-out |
| Standard Bsv2/Basv2 | 0 | 10 c/u | Alternativa si se necesita |

Decisión de tamaño de instancia: desplegar con **`Standard_B1s` (1 vCPU)** vía sobreescritura de `terraform.tfvars` en el despliegue (no se modifica el repositorio): permite 2 instancias por defecto (2 vCPU) y scale-out hasta 4 instancias (4 vCPU, límite BS), haciendo demostrable P1 (scale-out/scale-in). Con `Standard_B2s` el requisito E1 se cumple (mínimo 2) pero P1.3 (escala hacia arriba y hacia abajo) **no es demostrable** por cuota.

## 3. Recursos estimados a crear (alcance: laboratorio)

| Recurso | Detalle | Costo aproximado (24/7) |
|---------|---------|-------------------------|
| RG app + RG estado | rg-caribeshop-prod, rg-tfstate-caribeshop, eastus | $0 |
| VNet + subred snet-app + NSG | 10.0.0.0/16, 10.0.1.0/24, NSG mínimo | $0 |
| IP pública (LB) | Static, Standard | ~$3,50/mes |
| Load Balancer Standard | frontend público, backend pool, sonda /health:8080 | ~$16,60/mes |
| VMSS | 2× Standard_B1s (default), zonas 1-2-3, identidad SystemAssigned, cloud-init, autoscale (CPU 70/30, cooldowns 10m/15m), reparación automática, ignore_changes=[instances] | ~$45,40/mes (2 instancias) |
| Discos SO (Standard_LRS, 64 GiB c/u) | 2 unidades | ~$9,60/mes |
| Key Vault Standard | RBAC, purge protection, firewall (subred + IP operador), secreto con expiración | consumo por petición (mínimo) |
| Log Analytics (PerGB2018) | diagnóstico KV (AuditEvent) | ~$2,30/GB ingerido (mínimo en lab) |
| Azure Policy | Deny NIC con IP pública, asignada al RG | $0 |
| Action Group + alerta de métrica | CPU > 80%, 5 m, correo | $0 |
| Cuenta de almacenamiento backend | rg-tfstate-caribeshop, tfstatecaribeshop, contenedor tfstate | ~$1–2/mes |

**Total estimado si se deja en ejecución: ~$80–100/mes.** Suscripción Azure for Students: ≈$100 de crédito con límite de gasto. **Los recursos deben destruirse tras recoger evidencias (`terraform destroy`) para no agotar el crédito.**

Duración prevista: despliegue 5–10 min; pruebas P1 (≥25 min sostenido), P2, P3 ≈ 1–2 horas bajo supervisión continua. No se dejará Locust ni instancias sin supervisión.

## 4. Comprobaciones preflight ya ejecutadas

| Comprobación | Resultado |
|--------------|-----------|
| `git status` | Árbol limpio, rama `main`, commit `944c112` |
| `terraform fmt -check -recursive` | exit 0 (OK) |
| `terraform init -backend=false` | OK, azurerm v5.14.0 |
| `terraform validate` | Success! The configuration is valid. |
| Búsqueda de secretos en historial | Sin valores de secreto expuestos |
| Azure proveedores | Todos `Registered` |
| Grupos de recursos | `rg-caribeshop-prod` y `rg-tfstate-caribeshop` creados |

Pendiente: `terraform plan` (requiere `terraform.tfvars` local con valores sensibles del usuario) y revisión del plan antes del `apply`.

## 5. Plan de pruebas (solo si se autoriza el despliegue)

| Prueba | Alcance | Evidencia |
|--------|---------|-----------|
| P1a | Capacidad de 1 instancia: autoscale min=max=1 (reversible), Locust hasta p95 > 1 s; restaurar autoscale después | `evidencias/locust/` (CSV, HTML) |
| P1b | Perfil escalonado ≥25 min (subida/sostenida/bajada) | `evidencias/locust/` |
| P1c | Scale-out / scale-in con historial de instancias alineado con RPS/p95 de Locust | métricas de Azure + gráficos alineados |
| P2.1 | Falla lógica: `/health` → 503 en una instancia durante carga moderada; % de fallos y recuperación | `evidencias/fallas/` |
| P2.2 | Falla abrupta: eliminar una instancia del VMSS lab; errores, tiempo hasta recuperar mínimo, reparación automática | `evidencias/fallas/` |
| P3.1 | Lectura del secreto desde red no autorizada → bloqueo del firewall de KV (sin mostrar el secreto) | `evidencias/seguridad/` |
| P3.2 | Destino arbitrario de Internet bloqueado por NSG de egreso | `evidencias/seguridad/` |
| P3.3 | Violación reversible de la Policy Deny → `RequestDisallowedByPolicy` | `evidencias/seguridad/` |

## 6. Estructura de evidencias

`evidencias/inspeccion/` (hecha), `evidencias/preflight/` (hecha), `evidencias/terraform/` (por poblar: versiones, validate, plan sin secretos), `evidencias/azure/` (por poblar: zonas, roles, policy, autoscale, alertas, KQL), `evidencias/locust/`, `evidencias/fallas/`, `evidencias/seguridad/`, `evidencias/logs/`, `evidencias/resumen-final.md`.

## 7. Siguiente paso — acción requerida de tu parte

Crea localmente (no se sube a Git, está en `.gitignore`):

`terraform/environments/prod/terraform.tfvars`

con estos valores (tú los proporcionas; yo no los pido ni los manejo):
- `location = "eastus"`
- `resource_group_name = "rg-caribeshop-prod"`
- `project_name = "caribeshop"`
- `state_resource_group = "rg-tfstate-caribeshop"`
- `state_storage_account = "tfstatecaribeshop"`
- `state_container = "tfstate"`
- `vm_size = "Standard_B1s"` (recomendado; permite scale-out dentro de la cuota BS de 4 vCPU)
- `ssh_public_key = "<tu ssh-rsa ...>"`
- `operator_ip = "<tu-IP-publica/32>"`
- `key_vault_name = "<nombre-globalmente-unico>"`
- `secret_name = "app-secret"`
- `secret_value = "<valor-del-secreto>"` (sensible)
- `secret_expiration_date = "2027-12-31T23:59:59Z"`
- `alert_email = "<tu-correo>"`
- `instance_min = 2`, `instance_max = 4`, `instance_default = 2`

Cuando lo tengas listo, avísame y ejecuto:
1. `terraform init -backend-config="storage_account_name=tfstatecaribeshop"` (y `resource_group_name` si difiere del hardcodeado de backend.tf)
2. `terraform plan` — revisaré destrucciones/fuera de alcance/costos inesperados y guardaré el plan sin valores sensibles.
3. Con tu autorización explícita para `apply`, despliego.
