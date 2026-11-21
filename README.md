# ssha-platform

Plataforma cloud segura, escalable y altamente disponible en Azure: infraestructura como código con Terraform, pipeline DevSecOps con GitHub Actions y Checkov, autoscale multi-zona, gestión de secretos con Key Vault y validación mediante pruebas de carga y falla.

Caso CaribeShop (taller integrador UTB): plataforma segura que escale automáticamente y siga funcionando ante fallas de componente, todo desplegado como código en Azure.

## Arquitectura

- **Red**: VNet con subred de aplicación (`10.0.1.0/24`), NSG de mínimo privilegio (solo Azure Load Balancer, app en 8080, Key Vault en 443, IMDS en 80; todo lo demás denegado). Ninguna VM con IP pública. SSH/RDP no expuestos a Internet. (S2)
- **Compute**: VM Scale Set en 3 zonas de disponibilidad, mínimo 2 instancias, `Standard_B2s`, identidad administrada SystemAssigned, cloud-init de arranque (sin pasos manuales), reparación automática, autoscale con histeresis. (E1, E3, E4, D3)
- **Balanceador**: Load Balancer Standard con sonda de salud en `/health` (puerto 8080). (E2)
- **Secretos**: Key Vault con RBAC, purge protection, soft delete (90 días), firewall (subred de app + IP del operador), secreto con expiración, diagnóstico a Log Analytics. La app lee el secreto vía IMDS + identidad administrada y devuelve solo una huella (longitud + SHA-256 truncado), nunca el valor. (S3, S4, S6)
- **Gobierno**: Azure Policy Deny (NIC con IP pública) asignada al RG, alerta de CPU sostenida con notificación por correo, Log Analytics workspace. (S5, E5)
- **Estado**: backend remoto `azurerm` (Storage Account + contenedor), nunca en Git. (S1)

## Requisitos previos

- Suscripción de Azure con cuota suficiente para al menos 4 vCPU de la serie B en `eastus` (ver `az vm list-usage -l eastus -o table`).
- Azure CLI (`az`) instalado y autenticado (`az login`).
- Terraform >= 1.9.
- Una llave SSH pública (`ssh_public_key`).
- IP pública del operador para el firewall de Key Vault (`operator_ip`).
- Un nombre globalmente único para el Key Vault (`key_vault_name`).
- Un nombre globalmente único para la cuenta de almacenamiento del estado (`state_storage_account`).

## Despliegue

### 1. Bootstrap del backend remoto (una sola vez)

```bash
./scripts/bootstrap-backend.sh rg-tfstate <tfstate-storage-account> eastus
```

Edita `terraform/environments/prod/terraform.tfvars.example` -> `terraform.tfvars` con tus valores reales (nunca subas `terraform.tfvars`).

### 2. Desplegar

```bash
cd terraform/environments/prod
terraform init -backend-config="storage_account_name=<tfstate-storage-account>"
terraform plan
terraform apply
```

### 3. Destruir

```bash
terraform destroy
# Verificar en el portal de Azure que no queden recursos
```

## Variables requeridas

| Variable | Descripción | Ejemplo |
|---|---|---|
| `state_storage_account` | Cuenta de almacenamiento del estado remoto (único global) | `tfstatecaribeshop2026` |
| `state_resource_group` | RG del estado remoto | `rg-tfstate` |
| `ssh_public_key` | Llave SSH pública para las VM | `ssh-rsa AAAA...` |
| `operator_ip` | IP pública del operador (firewall KV) | `203.0.113.5/32` |
| `key_vault_name` | Nombre del Key Vault (único global) | `kv-caribeshop-2026` |
| `secret_value` | Valor del secreto de la app | (sensible, solo en tfvars) |
| `secret_expiration_date` | Fecha de expiración del secreto | `2027-12-31T23:59:59Z` |
| `alert_email` | Correo de alertas | `ops@example.com` |
| `instance_max` | Máximo de instancias (ver cuota VM) | `4` |

## Pipeline (GitHub Actions)

`.github/workflows/terraform.yml`:

- **PR**: `terraform fmt -check`, `terraform validate`, `terraform plan`, Checkov bloqueante (D1).
- **main**: `terraform apply` con Azure OIDC (sin credenciales en código).

Secrets requeridos en GitHub: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `TF_STATE_RG`, `TF_STATE_STORAGE`.

## Pruebas

- **P1 (carga y escalamiento)**: `locust -f locust/locustfile.py --host=http://<LB-IP> --csv evidencias/p1 --html evidencias/p1/reporte.html`
- **P2 (falla)**: marcar `/health` como 503 (falla lógica) o eliminar una instancia (falla abrupta), medir % de error.
- **P3 (seguridad)**: intentar leer el secreto desde red no autorizada; violar la Policy Deny y capturar `RequestDisallowedByPolicy`.

Evidencias en `evidencias/`.

## Checklist de línea base de seguridad

- [x] S1: Todo en Terraform, backend remoto `azurerm`, `.gitignore`, sin credenciales en código
- [x] S2: VNet con subred de app, NSG mínimo, ninguna VM con IP pública, SSH/RDP no expuestos
- [x] S3: App lee secreto de Key Vault con identidad administrada, RBAC, purge protection, firewall, expiración, solo huella
- [x] S4: Rol Key Vault Secrets User (solo lectura) asignado a la identidad del VMSS
- [x] S5: Azure Policy Deny asignada por Terraform al RG
- [x] S6: Diagnostic settings del Key Vault a Log Analytics
- [x] D1: Pipeline con fmt -check, validate, Checkov bloqueante
- [x] D2: Cada `# checkov:skip` con justificación (en el informe)
- [x] D3: cloud-init de arranque, sin pasos manuales

## Costos

VM serie B (`Standard_B2s`) con créditos de CPU limitados. No dejar pruebas de carga sin supervisión. Destruir recursos tras recoger evidencias.
