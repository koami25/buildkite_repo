terraform {
  required_version = ">= 1.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Auth comes from environment variables set by .buildkite/scripts/azure-login.sh:
# ARM_CLIENT_ID, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID, ARM_OIDC_TOKEN
provider "azurerm" {
  features {}
  use_oidc = true

  # Shared keys are disabled on the storage accounts, so data-plane calls use Entra ID
  storage_use_azuread = true
}
