# Verificación del workflow en GitHub Actions

Repositorio público `JOJA-TECH/ssha-platform`, PR #1 (`ci/verificacion` → `main`), 2026-11-22 UTC.

## Push a `main`

Run `45060911774`: `completed / skipped`. El job `apply` no se ejecuta porque `ENABLE_AZURE_APPLY` no está configurada; un push a `main` **no despliega** nada.

## PR a `main`

Se ejecutan `terraform fmt -check -recursive`, `terraform init -backend=false`, `terraform validate` y Checkov bloqueante, sin depender de secrets de Azure.

| Run | Escenario | Resultado |
|-----|-----------|-----------|
| `45060950067` | PR con la configuración final | `terraform: pass` (23 s), `apply: skipping` |
| `45061031462` | PR con hallazgo introducido a propósito (se quitó `content_type` del secreto) | `terraform: fail` (24 s) — Checkov `17 passed, 1 failed (CKV_AZURE_114), 2 skipped`; fmt/validate pasaron |
| `45061136940` | Hallazgo corregido (`content_type = "text/plain"`) | `terraform: pass` (22 s), `apply: skipping` |

Conclusión: el pipeline bloquea un hallazgo de seguridad real y vuelve a pasar al corregirlo; D1 queda verificado en ejecución.
