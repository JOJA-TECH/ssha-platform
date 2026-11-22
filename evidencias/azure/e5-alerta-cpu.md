# E5 — Alerta de Azure Monitor por CPU sostenida

Fuente: `az monitor metrics alert show -g rg-caribeshop-prod -n cpu-sostenido-vmss`, API `Microsoft.AlertsManagement/alerts?api-version=2019-05-05-preview`, métrica `Percentage CPU` del VMSS y `az vmss run-command invoke`. Todo sanitizado (sin ID de suscripción, correo enmascarado).

## Configuración de la regla

| Parámetro | Valor |
|-----------|-------|
| Regla | `cpu-sostenido-vmss` (habilitada) |
| Condición | `Percentage CPU` `Average > 80 %` |
| Ventana / frecuencia | `PT5M` / `PT1M` |
| Ámbito | VMSS `caribeshop-vmss` |
| Severidad | Sev2 |
| Acción | Action group `ag-caribeshop-alert` → correo `j***@utb.edu.co` (habilitado) |

## Prueba controlada

- `2026-11-22T20:00:13Z`: se inician 2 procesos `yes` por instancia en las 2 instancias del VMSS mediante `run-command` (`PROCESOS=2` en cada una).
- `20:03:45Z → 20:04:53Z`: CPU media del VMSS sube de 65,3 % a 99,7 %.
- `20:04:53Z → 20:14:17Z`: CPU sostenida ~99,7 % (>80 % durante más de 5 min, cumpliendo la ventana).
- `2026-11-22T20:09:52.989Z`: **la alerta dispara** — `monitorCondition: Fired`, `alertState: New`, `signalType: Metric`, regla `cpu-sostenido-vmss`.
- `20:14:17Z`: se detiene la carga (`pkill -x yes`) en ambas instancias; verificación `DETENIDOS=0` en instancia 1 y 2.

## Resultado

| Comprobación | Resultado |
|--------------|-----------|
| Regla de métrica evaluada y disparada | ✔ `Fired` a las 20:09:52Z |
| Umbral 80 % en ventana PT5M | ✔ CPU ~99,7 % sostenida ~10 min |
| Notificación por correo configurada | ✔ action group con `j***@utb.edu.co`, habilitado |
| Limpieza de la carga | ✔ 0 procesos `yes` restantes en ambas instancias |

Nota: el script de monitoreo local no reflejó el disparo en su salida porque buscaba el nombre de la alerta en `properties.name`, mientras la API lo expone en `name` de nivel superior; la alerta en Azure sí se generó y se confirma con la consulta directa al API de AlertsManagement. `autoMitigate` está activo, por lo que la alerta pasará a `Resolved` cuando la métrica baje de umbral (la latencia de métricas de Azure puede retrasar unos minutos este cambio).
