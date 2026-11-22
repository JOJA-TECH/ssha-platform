# Registros de comprobación locales (fase 2 — inspección)

Fecha: 2026-11-21 (UTC). Rama: `main`. Commit: `944c112`. Árbol de trabajo: limpio.
Todos los valores sensibles (claves, tokens, secretos de Terraform, correo completo) están omitidos o enmascarados.

## 1. Estado de Git

```
git branch --show-current  -> main
git status --short         -> (sin cambios sin commitear)
git log --oneline -4
944c112 feat(infrastructure): add README, fix CI backend config, apply terraform fmt
16d8f4a feat(infrastructure): add Azure VMSS, Key Vault, governance and Locust modules (azurerm 5.x)
6127753 feat(infrastructure): add Azure remote backend skeleton and CI workflow
6924af6 Initial commit
git remote -v              -> origin https://github.com/JOJA-TECH/ssha-platform (fetch/push)
```

Búsqueda de secretos en historial (`git log -p --all | grep -iE "secret|password|token|api.?key|-----BEGIN|AKIA"`): solo referencias a variables (`secret_value`, `secret_expiration_date`, `secrets.XXX` de GitHub Actions) y documentación. **No se imprimieron y no se hallaron valores de secreto.**

## 2. Herramientas disponibles

| Herramienta | Versión | Notas |
|-------------|---------|-------|
| terraform | Terraform v1.15.9 | Instalado |
| az | Azure CLI (autenticado) | `az account show` OK |
| gh | gh 2.105.0 | Logged in como `Jesus-MMM` (ADMIN en JOJA-TECH/ssha-platform) |
| python3 | Python 3.14.10 | Sin módulo `pip`; checkov y locust no instalados localmente |
| checkov | NO INSTALADO | No se pudo instalar localmente (no hay pip ni se asume red PyPI); se ejecuta en CI |
| locust | NO INSTALADO | Se instalará solo cuando se autoricen las pruebas de carga |

## 3. Identidad y suscripción de Azure

```
az account show  (enmascarado)
  name           : "Azure for Students" (id: e44b10e0-****-****-****-b9ad9454f0d1)
  state          : Enabled
  tenantId       : ea649e50-****-****-****-2fcffe16fd41  (Universidad Tecnológica de Bolívar)
  user           : jesm****@utb.edu.co (tipo: user)
az ad signed-in-user role assignment (scope suscripción)
  jesm****@utb.edu.co  Owner  /subscriptions/e44b10e0-...  -> permisos suficientes
```

## 4. Cuotas vCPU — `az vm list-usage -l eastus -o table` (extracto relevante)

| Medida | Uso | Límite |
|--------|-----|--------|
| Total Regional vCPUs | 0 | 6 |
| Standard BS Family vCPUs | 0 | 4 |
| Virtual Machine Scale Sets | 0 | 2500 |

Interpretación: `Standard_B2s` (2 vCPU) → máximo 2 instancias con la cuota BS; `Standard_B1s` (1 vCPU) → hasta 4 instancias. La disponibilidad de zonas no se pudo consultar por CLI (API de SKU sin respuesta en este entorno); eastus es región con zonas documentadas (1, 2, 3) y se verificará en el despliegue real.

## 5. Repositorio GitHub (gh)

```
gh repo view JOJA-TECH/ssha-platform -> viewerPermission: ADMIN, público
gh pr list --state all -> []  (cero pull requests)
gh secret list -> (vacío)  (no hay secretos de CI configurados)
gh run list -> 1 run: #1 push a main, conclusion=skipped (job terraform solo corre en PR; apply necesita push a main)
```

Consecuencia D1: el workflow tiene los checks bloqueantes (fmt -check, validate, Checkov), pero no hay ejecuciones verificables ni PRs.

## 6. Comprobaciones Terraform locales

Directorio: `terraform/environments/prod`

```
terraform fmt -check -recursive .   -> exit 0 (OK)
terraform init -backend=false       -> OK, azurerm v5.14.0 (lock file restaurado a su estado commiteado tras la prueba)
terraform validate                  -> Success! The configuration is valid.
```

No se ejecutó `terraform plan` localmente: requiere valores de variables sin default (`ssh_public_key`, `operator_ip`, `key_vault_name`, `secret_value`, `secret_expiration_date`, `alert_email`) y el grupo de recursos destino debe existir. El plan se ejecutará en la fase de preflight, justo antes del `apply`.

## 7. Estructura del repositorio (relevante)

Terraform: `environments/prod/{backend,main,outputs,providers,variables,versions}.tf`, `.terraform.lock.hcl`, `terraform.tfvars.example` (solo ejemplo, en .gitignore); módulos `virtual_network`, `key_vault`, `vmss` (con `files/app.py`, `files/cloud-init.tftpl`), `governance`.
Pipeline: `.github/workflows/terraform.yml`.
Pruebas: `locust/locustfile.py`.
Evidencias: `evidencias/.gitkeep` (vacía, por poblar).
