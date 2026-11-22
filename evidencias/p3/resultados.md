# P3 — Pruebas de seguridad (resultados)

Identificadores, IP y OID enmascarados. Los archivos raw pueden contener IP/OID del laboratorio, pero **ningún valor de secreto**.

## P3.1 — Secreto bloqueado desde red no autorizada

- Se eliminó temporalmente la regla de IP del operador del firewall del Key Vault (`kv-cshop-sub1-********`).
- `az keyvault secret show …` → **exit 1**, error `Forbidden` con código interno `ForbiddenByFirewall`: "Client address is not authorized and caller is not a trusted service".
- Se restauró la regla (`az keyvault network-rule add`) y la lectura volvió a **exit 0**.
- Confirmado además en auditoría: `SecretGet` del usuario con `ResultSignature = Forbidden` a las 19:08:35Z (ver `../azure/kql-kv-audit.md`).

raw: `kv-reglas-iniciales.json`, `lectura-sin-ip.err`, `lectura-sin-ip.out`.

## P3.2 — Filtrado de egreso

Desde una instancia del VMSS (`run-command`):

| Destino | Resultado |
|---------|-----------|
| `https://example.com` | `000` / `BLOQUEADO` |
| IMDS `169.254.169.254` | 200 |
| `/secret` local (vía Key Vault) | 200 |

Conclusión: la VM no sale a Internet arbitrario, pero conserva IMDS y acceso al Key Vault. raw: `egress-test.txt`.

## P3.3 — Violación de la Azure Policy (S5)

- Se creó una IP pública de prueba y se intentó una NIC con esa IP en `snet-app`.
- Azure rechazó la creación: **`RequestDisallowedByPolicy`**, política `deny-nic-public-ip` (`Deny public IP on network interfaces`).
- La IP pública de prueba fue eliminada; el listado de NICs con IP pública del RG quedó vacío.

raw: `policy-deny.err`, `policy-deny.out`.
