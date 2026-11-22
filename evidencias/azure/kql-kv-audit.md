# S6 — Auditoría del Key Vault en Log Analytics

Consulta ejecutada con `az monitor log-analytics query` sobre el workspace `caribeshop-law`. La consulta está en `kql-kv-audit.kql`. Salida sanitizada (OID e IP enmascarados; **sin valores de secreto**).

| Hora (UTC) | Tipo de identidad | IP origen | OID | Resultado | Cliente |
|------------|-------------------|-----------|-----|-----------|---------|
| 19:10:54 | user | 138.121.12.*** | 86e3e4c1… | OK | Terraform / proveedor azurerm |
| 19:10:29 | user | 138.121.12.*** | 86e3e4c1… | OK | Terraform / proveedor azurerm |
| 19:09:33 | **app** | 0.0.0.0 | **114b6233…** | **OK** | Python-urllib/3.10 (app en VMSS) |
| 19:08:43 | user | 138.121.12.*** | 86e3e4c1… | OK | Azure CLI |
| 19:08:35 | user | 138.121.12.*** | 86e3e4c1… | **Forbidden** | Azure CLI (P3.1: firewall sin la IP) |
| 19:06:48 … 19:06:32 | **app** | 0.0.0.0 | **114b6233…** | **OK** (varios eventos) | Python-urllib/3.10 (app en VMSS) |

## Interpretación

- El OID `114b6233…` corresponde a la **identidad administrada del VMSS** (coincide con el `principal_id` del role assignment de Terraform), con `identity_claim_idtyp_s = app` y origen `0.0.0.0` típico de acceso por service endpoint desde la subred.
- El mismo usuario con rol aparece permitido con su IP autorizada y rechazado (`Forbidden`) cuando se retiró la regla en P3.1: el firewall, no el RBAC, es el control que bloquea.
- Queda demostrada la lectura del secreto por la identidad del VMSS en los logs (S6) y el bloqueo por red no autorizada (P3.1).
