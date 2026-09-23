terraform {
  required_version = ">= 1.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Auth comes from environment variables set in the pipeline:
# ARM_CLIENT_ID, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID, ARM_OIDC_TOKEN
provider "azurerm" {
  features {}
  use_oidc = true
}
