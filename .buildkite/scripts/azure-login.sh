#!/usr/bin/env bash
# Sets up Azure auth for terraform with Buildkite OIDC (no az CLI needed).
# Must be sourced so the exports reach the calling step.
set -euo pipefail

AZURE_CLIENT_ID=$(buildkite-agent secret get AZURE_CLIENT_ID)
AZURE_TENANT_ID=$(buildkite-agent secret get AZURE_TENANT_ID)
TOKEN=$(buildkite-agent oidc request-token --audience "api://AzureADTokenExchange")

# Subscription: use the AZURE_SUBSCRIPTION_ID secret if it exists,
# otherwise look up the one subscription the service principal can see.
AZURE_SUBSCRIPTION_ID=$(buildkite-agent secret get AZURE_SUBSCRIPTION_ID 2>/dev/null || true)
if [[ -z "$AZURE_SUBSCRIPTION_ID" ]]; then
  ACCESS_TOKEN=$(curl -fsS -X POST \
    "https://login.microsoftonline.com/$AZURE_TENANT_ID/oauth2/v2.0/token" \
    --data-urlencode "client_id=$AZURE_CLIENT_ID" \
    --data-urlencode "grant_type=client_credentials" \
    --data-urlencode "scope=https://management.azure.com/.default" \
    --data-urlencode "client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer" \
    --data-urlencode "client_assertion=$TOKEN" \
    | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')

  SUBSCRIPTIONS=$(curl -fsS -H "Authorization: Bearer $ACCESS_TOKEN" \
    "https://management.azure.com/subscriptions?api-version=2022-12-01" \
    | grep -o '"subscriptionId":"[^"]*"' | cut -d'"' -f4 | sort -u)

  if [[ $(printf '%s\n' "$SUBSCRIPTIONS" | grep -c .) -ne 1 ]]; then
    echo "Expected exactly 1 subscription, found: ${SUBSCRIPTIONS:-none}"
    echo "Create a Buildkite secret AZURE_SUBSCRIPTION_ID with the one to use."
    exit 1
  fi
  AZURE_SUBSCRIPTION_ID="$SUBSCRIPTIONS"
fi

# Credentials for the terraform azurerm provider and backend
export ARM_USE_OIDC=true
export ARM_CLIENT_ID="$AZURE_CLIENT_ID"
export ARM_TENANT_ID="$AZURE_TENANT_ID"
export ARM_OIDC_TOKEN="$TOKEN"
export ARM_SUBSCRIPTION_ID="$AZURE_SUBSCRIPTION_ID"
echo "Using tenant $ARM_TENANT_ID, subscription $ARM_SUBSCRIPTION_ID"
