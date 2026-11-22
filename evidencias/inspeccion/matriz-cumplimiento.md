# Matriz de cumplimiento — estado final (inspección + ejecución)

Repositorio: `JOJA-TECH/ssha-platform`, rama `main`, commit `944c112` (cambios locales sin commitear).
Ejecución: `Azure subscription 1`, `eastus`, laboratorio aislado. Fecha 2026-11-22 (UTC).
Identificadores, IP, OID y correos enmascarados. El valor del secreto nunca se imprimió ni se guardó.

Estado: `cumple` | `parcial` | `no cumple` | `no verificable`.
Fuentes: código Terraform/workflows, comandos de Azure CLI, Locust (CSV/HTML) y consultas KQL. Ver `../azure/despliegue-sub1.md`, `../p1/resultados.md`, `../p2/resultados.md`, `../p3/resultados.md`.

## Seguridad

| ID | Estado | Evidencia de ejecución | Observaciones |
|----|--------|------------------------|---------------|
| **S1** | cumple | Backend `azurerm` inicializado con cuenta única; `apply` 20 recursos; `terraform plan -detailed-exitcode` → 0 (`No changes`); sin `.tfstate` en Git | `terraform init` añadió un hash de plataforma a `.terraform.lock.hcl` (cambio local, sin secretos). |
| **S2** | cumple | NSG con `AllowHealthProbe` (AzureLoadBalancer), `AllowAppInbound` (VNet:8080), `AllowOperatorInbound` (IP operador/32:8080) y `DenyAllInbound`; NICs del VMSS sin IP pública; P3.2: Internet bloqueado, IMDS y KV accesibles | Se añadió la regla del operador porque sin ella el NSG bloqueaba también el tráfico real del cliente (sólo pasaba la sonda). |
| **S3** | cumple | KV con RBAC, purge protection, soft-delete 90 días, firewall `Deny` + subred + IP operador; secreto expira 2027-12-31; `/secret` devuelve `len=48 sha256=7eb1c3fa22fb1a8e`; P3.1 `ForbiddenByFirewall`; KQL confirma `SecretGet` por la identidad del VMSS | `publicNetworkAccess = Enabled` es necesario para que el firewall (`network_acls`) filtre; sin él, Azure bloquea por defecto. |
| **S4** | cumple | Role assignment `Key Vault Secrets User` sobre el KV para la identidad SystemAssigned del VMSS; KQL muestra el OID `114b6233…` (`idtyp = app`) leyendo el secreto | Adicionalmente se asignó `Key Vault Secrets Officer` al usuario a ámbito RG para gestionar el secreto del lab; no es un rol de la VMSS. |
| **S5** | cumple | Intento de NIC con IP pública rechazado: `RequestDisallowedByPolicy`, política `deny-nic-public-ip` (`Deny`, `enforce = true`); IP de prueba eliminada | Ver `../p3/resultados.md`. |
| **S6** | cumple | Diagnostic setting KV → Log Analytics desplegado; consulta KQL ejecutada con eventos `SecretGet` (incluido el `Forbidden` de P3.1) | Plantilla y salida sanitizada en `../azure/kql-kv-audit.{kql,md}`. |

## Escalamiento y alta disponibilidad

| ID | Estado | Evidencia | Observaciones |
|----|--------|-----------|---------------|
| **E1** | cumple | VMSS en zonas `[1,2]`, 2 instancias; zona confirmada por IMDS en cada una (1 y 2) | `D2as_v4` (2 vCPU) con cuota regional de 4 vCPU: no caben más instancias. |
| **E2** | cumple | Sonda HTTP `/health:8080` en el LB; `/health` → 200 tanto local como por LB; P2.1 demuestra que una sonda 503 retira la instancia del balanceo | No se capturó por separado la métrica `Health Probe Status`. |
| **E3** | cumple | Código con histeresis (70/30) y cooldowns 10/15 min; Activity Log: `ScaledownResult` 2→1 (18:22:08Z) y `ScaleupResult` 1→2 (18:27:49Z) ejecutados por `Microsoft.Insights/autoscaleSettings`; correo de notificación recibido | Detalle en `../azure/autoscale-eventos.md`. Las acciones fueron por cambio controlado del perfil en P1.1, no por umbral de CPU: con `instance_max = 2` no cabe `+2`. La API `runHistory` sigue disponible sólo como Activity Log. |
| **E4** | parcial | `automatic_instance_repair { enabled = true, grace_period = "PT30M" }` y `rolling_upgrade_policy` declarada en código | No se presenció reemplazo automático: en P2.2 la instancia apagada se reinició manualmente. |
| **E5** | parcial | Alerta de métrica CPU >80 %/5 min + action group con correo desplegados | No hay correo recibido ni historial de alertas capturado durante el lab. |

## DevSecOps

| ID | Estado | Evidencia | Observaciones |
|----|--------|-----------|---------------|
| **D1** | cumple | PR #1: run `45060950067` pass; run `45061031462` **fail** por `CKV_AZURE_114` introducido a propósito; run `45061136940` pass tras corregirlo; push a main `45060911774` skipped (sin apply automático) | Detalle en `verificacion-ci.md`. El workflow de PR no depende de secrets; Checkov es bloqueante. |
| **D2** | cumple | Checkov 3.4.6 sobre `terraform/environments/prod`: **18 passed, 0 failed, 2 skipped**; ambos skips llevan justificación en código | Tabla de riesgos aceptados más abajo. El hallazgo `CKV_AZURE_114` se corrigió de verdad (`content_type = "text/plain"`), no se omitió. |
| **D3** | cumple | cloud-init corregido (YAML validado: 3 `write_files`, 3 `runcmd`) y aplicado; app activa en las 2 instancias tras el arranque, sin pasos manuales | Se eliminaron `owner:` (el usuario no existe aún en `write_files`) y `package_update` (egreso cerrado). `indent()` no indenta la primera línea: se añadieron 6 espacios explícitos en la plantilla. |

## Pruebas obligatorias

| ID | Estado | Resultado |
|----|--------|-----------|
| **P1.1** | cumple | 1 instancia: 700 peticiones, 186 fallos (26,6 %), p95 ~136 s, ~2,36 RPS. |
| **P1.2** | cumple | Perfil 25 min: 26.022 peticiones, 11 fallos (0,04 %), 17,43 RPS, p95 2,3 s; CSV + HTML guardados. |
| **P1.3** | cumple | Línea de tiempo alineada: scale-in 2→1 y scale-out 1→2 del autoscale frente a RPS/p95 de P1.1 (`../p1/escalamiento-linea-tiempo.md`) | Los cambios fueron por el perfil 1/1 → 2/2/2, no por CPU (cuota máxima 2). Se entrega tabla alineada en vez de imagen de gráfico. |
| **P2.1** | cumple | Falla lógica (`/health` → 503): 1.001 peticiones, 0 fallos. |
| **P2.2** | cumple | Instancia apagada: 1.067 peticiones, 0 fallos; recuperada manualmente. |
| **P3.1** | cumple | Sin IP autorizada: `ForbiddenByFirewall`; restaurada la regla, lectura OK. |
| **P3.2** | cumple | `example.com` bloqueado, IMDS 200, `/secret` local 200. |
| **P3.3** | cumple | `RequestDisallowedByPolicy` / `deny-nic-public-ip` capturado. |

## Entrega y documentación

| Elemento | Estado | Observación |
|----------|--------|-------------|
| Código Terraform modular + app + locustfile + workflow | cumple | `locustfile.py` corregido: `StagesShape` no existe en Locust; implementado con `LoadTestShape`. |
| `evidencias/` | cumple | Inspección, preflight, terraform, azure, P1, P2, P3 y resumen final. |
| Dos PRs cerrados (hallazgo + corrección) | parcial | PR #1 fusionado con fallo por Checkov y corrección; el taller pide dos PRs, sólo hay uno. |
| Informe PDF (≤ 12 págs.) y video 6–8 min | no verificable | Entregables grupales posteriores; fuera de este lab. |

## Riesgos aceptados (D2)

| Check | Recurso | Riesgo | Justificación |
|-------|---------|--------|---------------|
| `CKV2_AZURE_32` | `azurerm_key_vault.this` | Sin private endpoint: el KV se alcanza por service endpoint + firewall de red | El requisito S3 pide explícitamente firewall (subred + IP del operador) y P3.1 lo demuestra; un private endpoint cambiaría el diseño de red y el filtrado de egreso del lab. |
| `CKV_AZURE_97` | `azurerm_linux_virtual_machine_scale_set.vmss` | Sin cifrado en host (VM) | Laboratorio sin datos sensibles locales; los discos ya están cifrados en reposo por Azure y habilitarlo fuerza el reemplazo del VMSS. |

## Puerta de decisión y estado del laboratorio

- No hay incumplimiento obligatorio de código ni secretos expuestos. El despliegue se ejecutó en `Azure subscription 1` tras superar preflight y verificar plan; las correcciones se hicieron con plan revisado.
- **Límites del entorno, no del código**: cuota de 4 vCPU (impide P1.3/E3 real), API de historial del autoscale no disponible, y D1 sin ejecución de CI por falta de secretos/PRs.
- **El laboratorio sigue en ejecución y generando costo.** No hay autorización para `terraform destroy`; queda pedirla explícitamente. Las evidencias se conservan aunque se destruya.
