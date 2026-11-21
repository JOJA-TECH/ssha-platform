provider "azurerm" {
  features {}

  # La autenticación NO se declara aquí: se resuelve mediante el entorno de
  # ejecución (az login, variables de entorno ARM_* o identidad federada de
  # GitHub Actions OIDC), sin incluir credenciales en el código.
}
