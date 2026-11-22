# P1.3 — Scale-in/scale-out alineado con la carga

Línea de tiempo construida con el Activity Log de Azure (`../azure/autoscale-eventos.md`) y `p1-capacidad/carga_stats_history.csv` (marcas de tiempo convertidas de epoch a UTC). IP y datos de suscripción enmascarados.

| Hora UTC | Instancias | Usuarios Locust | RPS | p95 | Evento |
|----------|-----------|-----------------|-----|-----|--------|
| 18:22:08 | **2 → 1** | — | — | — | Autoscale `ScaledownResult` (perfil 1/1 para P1.1) |
| 18:22:25 | 1 | 0 | 0,0 | — | Inicio de Locust |
| 18:24:55 | 1 | 200 | 0,6 | 11 s | Rampa de carga |
| 18:27:24 | 1 | 200 | 4,4 | 136 s | Saturación de la instancia única |
| 18:27:49 | **1 → 2** | — | — | — | Autoscale `ScaleupResult` (restauración a 2/2/2) |
| 18:34:14 – 19:00:07 | 2 | 50 | hasta 22,6 | ~0,76 s | P1.2 escalonado de 25 min, sin cambios de instancias |

Conclusión: el scale-in y el scale-out están alineados en el tiempo con la ventana de P1.1; el paso a 1 instancia explica la degradación del p95 y el paso a 2 la recuperación posterior.

**Limitación**: estos cambios fueron provocados por el ajuste del perfil de autoscale, no por los umbrales de CPU (E3). El gráfico de instancias en el tiempo se entrega como esta tabla alineada; los CSV originales están en `p1-capacidad/` y `instancias.csv`.
