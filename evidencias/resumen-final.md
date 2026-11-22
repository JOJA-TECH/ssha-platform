# Resumen final del laboratorio CaribeShop

Todo lo que sigue está sanitizado (sin secretos, tokens ni contenido del estado). Los CSV/HTML/salidas crudos también fueron enmascarados antes de subirlos a este repositorio público (IP, OID, IDs de suscripción y nombres de recursos). Evidencia detallada: `inspeccion/matriz-cumplimiento.md`, `azure/despliegue-sub1.md`, `p1/resultados.md`, `p2/resultados.md`, `p3/resultados.md`.

## Resultado

- **Desplegado** en `Azure subscription 1` / `eastus`: 20 recursos, VMSS `D2as_v4` con 2 instancias en zonas 1 y 2, LB con sonda `/health`, Key Vault con RBAC + firewall + secreto con expiración, Log Analytics, política Deny, alerta y backend remoto de Terraform.
- **Estado final limpio**: `terraform plan` → `No changes`; `/health` → 200; `/secret` devuelve sólo huella.
- **Pruebas**: P1.1 (capacidad de 1 instancia), P1.2 (25 min escalonado), P2.1/P2.2 (fallas lógica y abrupta, 0 % de errores) y P3.1–P3.3 (firewall KV, egress, política Deny) ejecutadas con CSV/HTML y salidas guardadas.

## Limitaciones que deben declararse en el informe

1. **E3 / P1.3 demostrados**: el Activity Log registra scale-in 2→1 y scale-out 1→2 ejecutados por el autoscale y se recibió el correo de notificación (`azure/autoscale-eventos.md`, `p1/escalamiento-linea-tiempo.md`). No obstante, la cuota de 4 vCPU fija `instance_max = 2`, así que **no se disparó un scale-out por la regla de CPU**; las acciones fueron por el cambio controlado del perfil en P1.1.
2. **E4 / E5 siguen sin evidencia empírica**: reparación automática y alerta de métrica por correo configuradas, sin evento observado (el correo recibido es de autoscale, no de la alerta `cpu-sostenido-vmss`).
3. **D1 verificado** en PR #1 (fallo por Checkov introducido a propósito + corrección; ver `inspeccion/verificacion-ci.md`). PR #2 también fusionado, quedando cubierto el requisito de dos PRs.
4. Ya hay commits, push y un PR fusionado; el laboratorio de Azure sigue desplegado.

## Estado operativo

El laboratorio **sigue en ejecución y facturando**. No se ha autorizado `terraform destroy` para esta suscripción; al recibir la autorización se destruirá `rg-caribeshop-prod` y el backend, conservando toda la evidencia bajo `evidencias/`.
