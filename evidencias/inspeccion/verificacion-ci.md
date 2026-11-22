# Verificación del workflow en GitHub Actions

Push a `main`: el job `apply` queda en `skipped` porque `ENABLE_AZURE_APPLY` no está configurada; no hay despliegue automático.

PR a `main`: se ejecutan `terraform fmt -check -recursive`, `terraform init -backend=false`, `terraform validate` y Checkov bloqueante, sin depender de secrets de Azure.

Resultado del PR de verificación: pendiente.
