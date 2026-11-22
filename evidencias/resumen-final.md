# Resumen final del laboratorio CaribeShop

Todo lo que sigue está sanitizado (sin secretos, tokens ni contenido del estado). Los CSV/HTML/salidas crudos también fueron enmascarados antes de subirlos a este repositorio público (IP, OID, IDs de suscripción y nombres de recursos). Evidencia detallada: `inspeccion/matriz-cumplimiento.md`, `azure/despliegue-sub1.md`, `p1/resultados.md`, `p2/resultados.md`, `p3/resultados.md`.

## Resultado

- **Desplegado** en `Azure subscription 1` / `eastus`: 20 recursos, VMSS `D2as_v4` con 2 instancias en zonas 1 y 2, LB con sonda `/health`, Key Vault con RBAC + firewall + secreto con expiración, Log Analytics, política Deny, alerta y backend remoto de Terraform.
- **Estado final limpio**: `terraform plan` → `No changes`; `/health` → 200; `/secret` devuelve sólo huella.
- **Pruebas**: P1.1 (capacidad de 1 instancia), P1.2 (25 min escalonado), P2.1/P2.2 (fallas lógica y abrupta, 0 % de errores) y P3.1–P3.3 (firewall KV, egress, política Deny) ejecutadas con CSV/HTML y salidas guardadas.

## Limitaciones que deben declararse en el informe

1. **P1.3 / E3 incompleto**: cuota de 4 vCPU impide `instance_max > 2`, por lo que no hubo scale-out/in por CPU; la API de historial del autoscale no está disponible (`Unrecognized operationName: runHistory`).
2. **E4 / E5**: reparación automática y alerta por correo configuradas, sin evento observado durante el lab.
3. **D1 parcial**: sin secretos de GitHub ni PRs; Checkov no ejecutado localmente.
4. **No se crearon commits, push ni PRs**; todos los cambios siguen locales.

## Estado operativo

El laboratorio **sigue en ejecución y facturando**. No se ha autorizado `terraform destroy` para esta suscripción; al recibir la autorización se destruirá `rg-caribeshop-prod` y el backend, conservando toda la evidencia bajo `evidencias/`.
