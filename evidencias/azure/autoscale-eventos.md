# E3 — Historial de ejecución del autoscale

Fuente: `az monitor activity-log list -g rg-caribeshop-prod --start-time 2026-11-22T18:20:00Z --end-time 2026-11-22T18:30:00Z`.
Valores sanitizados (sin subscription ID, OID ni correo). Operaciones `Microsoft.Insights/AutoscaleSettings/*`.

| Hora UTC | Operación | Estado | Instancias antes → después | Caller |
|----------|-----------|--------|----------------------------|--------|
| 18:22:08.844Z | `Scaledown/Action`, `ScaledownResult/Action` | Succeeded | **2 → 1** | `Microsoft.Insights/autoscaleSettings` |
| 18:27:49.734Z | `Scaleup/Action`, `ScaleupResult/Action` | Succeeded | **1 → 2** | `Microsoft.Insights/autoscaleSettings` |

Detalle del scale-up: `OldInstancesCount = 1`, `NewInstancesCount = 2`; perfil activo `default` con `Minimum = Maximum = Default = 2`, reglas CPU `> 70 %` (+2, cooldown 10 min) y `< 30 %` (−1, cooldown 15 min). El scale-down ocurrió al poner temporalmente el perfil en 1/1 para P1.1 y el scale-up al restaurarlo a 2/2/2.

## Correo recibido

El autoscale tiene configurada una notificación por correo (`notification { email { custom_emails = [var.alert_email] } }`, operación `Scale`, correo enmascarado `j***@utb.edu.co`). El correo que reporta "scale started" para `caribeshop-vmss` corresponde a la acción de scale-up de las 18:27:49Z.

## Alcance de la evidencia

- Queda demostrado que el motor de autoscale **ejecutó** scale-in y scale-out y que notificó por correo.
- **No** se demostró un scale-out disparado por la regla de CPU: la cuota de 4 vCPU fija `instance_max = 2`, así que con 2 instancias no hay margen para aplicar `+2`. Las acciones ocurrieron por el cambio controlado del perfil durante P1.1.
- La API `autoscaleSettings/…/runHistory` sigue sin estar disponible (`Unrecognized operationName: runHistory`); este historial se obtuvo del Activity Log de Azure.
