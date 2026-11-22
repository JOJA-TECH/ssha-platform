# E4 — Reparación automática de instancias

Fuente: `az vmss list-instances`, `az vmss get-instance-view`, `az vmss run-command invoke` y `az monitor activity-log list`. Identificadores de VM enmascarados; sin ID de suscripción, IP ni correos.

## Configuración

| Parámetro | Valor |
|-----------|-------|
| `automatic_instance_repair.enabled` | `true` |
| `grace_period` | `PT30M` |
| `health_probe_id` | sonda LB `Http :8080 /health` (intervalo 5 s, 2 fallos) |
| `upgrade_mode` | `Automatic` |
| Instancias | 2 (zonas 1 y 2) |

## Prueba controlada

| Hora UTC | Acción / observación |
|----------|----------------------|
| 20:19:05 | Inicio de la prueba; instancia 1 con `vmId 23c1e1d9-…-a52b093cd852` |
| 20:19:57 | `systemctl stop caribeshop.service` en instancia 1 vía `run-command` → `ESTADO=inactive`, `/health` local `000` (FAIL) |
| 20:20:27 | Azure reporta la instancia 1 como `HealthState/unhealthy` |
| 20:21 – 20:49 | Sin cambios de `vmId`; el LB sigue devolviendo `200` con la instancia 2. Se cumple el grace period de 30 min |
| 20:51:26 | La instancia 1 desaparece de `list-instances` (sólo queda la instancia 2) |
| 20:55:10 | Aparece la **instancia 3** con `vmId 07746bfa-…-289f7d7d236c` (nuevo); `sku.capacity` vuelve a 2 |
| 20:56:33 | Instancia 3 en `HealthState/healthy`; servicio `active` y `/health` local `200` |

## Resultado

| Comprobación | Resultado |
|--------------|-----------|
| Health probe detecta la instancia no saludable | ✔ `HealthState/unhealthy` a las 20:20:27Z |
| Reparación tras el grace period (30 min) | ✔ sustitución ~31 min después (20:51Z) |
| Instancia reemplazada con VM nueva | ✔ vmId `23c1e1d9…` → `07746bfa…` (instancia 3) |
| Servicio recuperado sin intervención manual | ✔ `active`, `/health` local `200`, `HealthState/healthy` |
| Capacidad y disponibilidad del LB | ✔ `sku.capacity = 2`, `/health` público `200` durante toda la prueba |

Nota: la reparación automática es una operación de plataforma de Azure y **no aparece como evento en Activity Log** (sólo se registran los `run-command` manuales); la evidencia es el cambio de `vmId`, la desaparición de la instancia 1, la creación de la instancia 3 y su estado `healthy` posterior. No se reinició ni restauró ninguna instancia manualmente durante la ventana de gracia.
