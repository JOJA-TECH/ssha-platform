# P1 — Carga y escalamiento (resultados)

Host de pruebas: LB `http://172.172.182.***` (IP enmascarada). Locust 2.15.0 en entorno aislado `/tmp/locust-venv`. CSV y HTML originales en esta carpeta y en `../p1-capacidad/`.

## P1.1 — Capacidad de una instancia

- Autoscale cambiado temporalmente a `min = default = max = 1` (`az monitor autoscale update`), esperando a que el VMSS bajara a 1 instancia.
- Carga: 200 usuarios, spawn rate 10/s, 5 min.

| Métrica | Resultado |
|---------|-----------|
| Peticiones | 700 |
| Fallos | 186 (**26,6 %**) |
| RPS | ~2,36 |
| p95 | ~136 s |
| Latencia media | ~36,6 s |

Conclusión: una sola instancia satura y deja de responder bajo la rampa; se reinició el servicio y se restauró el autoscale a 2/2/2 antes de continuar. raw: `../p1-capacidad/carga_*.csv`, `reporte.html`.

## P1.2 — Perfil escalonado ≥ 25 min

- `locust/locustfile.py`: subida 5 min → meseta 15 min → bajada 5 min (25 min), implementado con `LoadTestShape` (la importación original `StagesShape` no existe en Locust).
- Muestreo de capacidad cada 30 s en `instancias.csv`.

| Métrica | Resultado |
|---------|-----------|
| Peticiones | 26.022 |
| Fallos | 11 (**0,04 %**) |
| RPS | 17,43 |
| p95 | 2,3 s |
| Latencia media | 309 ms |
| Instancias observadas | 2 durante toda la ventana |

raw: `carga_*.csv`, `reporte.html`, `instancias.csv`.

## P1.3 — Scale-out / scale-in

**No demostrado por cuota**: `instance_max = 2` (4 vCPU regionales, SKU de 2 vCPU). El perfil P1.2 nunca superó 2 instancias y no hubo historial de ejecución del autoscale (la API `runHistory` devuelve `Unrecognized operationName`). Ver `../azure/despliegue-sub1.md`.
