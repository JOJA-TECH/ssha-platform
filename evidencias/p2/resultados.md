# P2 — Pruebas de falla (resultados)

Carga moderada: 20 usuarios, spawn rate 5/s, 2 min por escenario. IP del LB enmascarada. CSV y HTML originales en esta carpeta.

## P2.1 — Falla lógica

- Se creó el flag `/opt/caribeshop/unhealthy` en la instancia 1; su `/health` local pasó a **503** (verificado por `run-command`).
- Durante la carga, el balanceador siguió enviando tráfico a la instancia sana.

| Métrica | Resultado |
|---------|-----------|
| Peticiones | 1.001 |
| Fallos | **0 (0 %)** |
| RPS | 8,41 |
| p95 | 3,9 s |

Tras la prueba se eliminó el flag y el `/health` local volvió a 200. raw: `fallo-logico_*.csv`, `fallo-logico.html`.

## P2.2 — Falla abrupta

- Se apagó la instancia 2 con `az vmss stop --instance-ids 2` (nota de Azure: sigue facturándose; se reinició al terminar).
- La instancia 1 absorbió toda la carga.

| Métrica | Resultado |
|---------|-----------|
| Peticiones | 1.067 |
| Fallos | **0 (0 %)** |
| RPS | 8,97 |
| p95 | 0,48 s |

Tras reiniciar la instancia 2, el `/health` del LB volvió a 200. La instancia fue recuperada manualmente; no se observó reemplazo automático (E4 queda como configurado, no demostrado). raw: `fallo-abrupto_*.csv`, `fallo-abrupto.html`.
