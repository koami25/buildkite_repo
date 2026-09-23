#!/usr/bin/env bash
# Logs in to Azure with Buildkite OIDC and exports ARM_* for terraform.
# Must be sourced so the exports reach the calling step.
set -euo pipefail

export AZURE_CLIENT_ID=$(buildkite-agent secret get AZURE_CLIENT_ID)
export AZURE_TENANT_ID=$(buildkite-agent secret get AZURE_TENANT_ID)
TOKEN=$(buildkite-agent oidc request-token --audience "api://AzureADTokenExchange")

az login --service-principal \
  --username "$AZURE_CLIENT_ID" \
  --tenant "$AZURE_TENANT_ID" \
  --federated-token "$TOKEN" \
  --output none
az account show

# Same OIDC credentials for the Terraform azurerm provider and backend
export ARM_USE_OIDC=true
export ARM_CLIENT_ID="$AZURE_CLIENT_ID"
export ARM_TENANT_ID="$AZURE_TENANT_ID"
export ARM_OIDC_TOKEN="$TOKEN"
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
