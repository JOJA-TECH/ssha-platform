#!/usr/bin/env bash
# Crea los recursos prerequisitos para el backend remoto de Terraform (azurerm):
# grupo de recursos, cuenta de almacenamiento y contenedor de blobs.
# Equivalente al bootstrap S3 + DynamoDB del flujo de AWS.
set -euo pipefail

usage() {
  echo "Uso: $0 <rg-tfstate> <cuenta-almacenamiento> <ubicacion> [grupo-recursos-app]"
  exit 1
}

RG_TFSTATE="${1:-$(usage)}"
STORAGE_ACCOUNT="${2:-$(usage)}"
LOCATION="${3:-eastus}"

echo "==> Creando grupo de recursos para el estado: $RG_TFSTATE"
az group create --name "$RG_TFSTATE" --location "$LOCATION" >/dev/null

echo "==> Creando cuenta de almacenamiento: $STORAGE_ACCOUNT"
az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RG_TFSTATE" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --https-only true >/dev/null

echo "==> Creando contenedor tfstate"
az storage container create \
  --account-name "$STORAGE_ACCOUNT" \
  --name tfstate \
  --auth-mode login >/dev/null

echo "OK: backend remoto listo. Usa:"
echo "  state_resource_group = \"$RG_TFSTATE\""
echo "  state_storage_account = \"$STORAGE_ACCOUNT\""
echo "  state_container      = \"tfstate\""
