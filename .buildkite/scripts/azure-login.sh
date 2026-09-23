#!/usr/bin/env bash
# Sets up Azure auth for terraform with Buildkite OIDC (no az CLI needed).
# Must be sourced so the exports reach the calling step.
set -euo pipefail

# Strip stray whitespace/quotes that often sneak in when pasting secrets
clean() { printf '%s' "$1" | tr -d '[:space:]"'"'"; }

# Per-environment secrets (e.g. AZURE_CLIENT_ID_PROD) win over the shared ones,
# so each environment can use its own managed identity and subscription.
ENV_SUFFIX=$(printf '%s' "${TF_ENV:-}" | tr '[:lower:]' '[:upper:]')
secret() {
  local value=""
  if [[ -n "$ENV_SUFFIX" ]]; then
    value=$(buildkite-agent secret get "${1}_${ENV_SUFFIX}" 2>/dev/null || true)
  fi
  if [[ -z "$value" ]]; then
    value=$(buildkite-agent secret get "$1" 2>/dev/null || true)
  fi
  clean "$value"
}

AZURE_CLIENT_ID=$(secret AZURE_CLIENT_ID)
AZURE_TENANT_ID=$(secret AZURE_TENANT_ID)

GUID_RE='^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
for name in AZURE_CLIENT_ID AZURE_TENANT_ID; do
  if [[ ! "${!name}" =~ $GUID_RE ]]; then
    value="${!name}"
    echo "Secret $name is not a GUID (got ${#value} characters, expected 36)."
    echo "Expected format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    exit 1
  fi
done
if [[ "$AZURE_CLIENT_ID" == "$AZURE_TENANT_ID" ]]; then
  echo "AZURE_CLIENT_ID and AZURE_TENANT_ID have the same value; one of them is wrong."
  exit 1
fi
# sub = cluster UUID, so one federated credential on the managed identity
# covers every pipeline in the cluster (Azure needs an exact subject match).
TOKEN=$(buildkite-agent oidc request-token \
  --audience "api://AzureADTokenExchange" \
  --subject-claim cluster_id)

# Subscription: use the AZURE_SUBSCRIPTION_ID[_ENV] secret if it exists,
# otherwise look up the one subscription the identity can see.
AZURE_SUBSCRIPTION_ID=$(secret AZURE_SUBSCRIPTION_ID)
if [[ -z "$AZURE_SUBSCRIPTION_ID" ]]; then
  TOKEN_RESPONSE=$(curl -sS -X POST \
    "https://login.microsoftonline.com/$AZURE_TENANT_ID/oauth2/v2.0/token" \
    --data-urlencode "client_id=$AZURE_CLIENT_ID" \
    --data-urlencode "grant_type=client_credentials" \
    --data-urlencode "scope=https://management.azure.com/.default" \
    --data-urlencode "client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer" \
    --data-urlencode "client_assertion=$TOKEN")
  ACCESS_TOKEN=$(printf '%s' "$TOKEN_RESPONSE" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')

  if [[ -z "$ACCESS_TOKEN" ]]; then
    echo "Azure rejected the Buildkite OIDC token:"
    printf '%s' "$TOKEN_RESPONSE" | sed -n 's/.*"error_description":"\([^"]*\)".*/\1/p'
    # Show the (non-secret) claims Azure matches against the federated credential
    PAYLOAD=$(printf '%s' "$TOKEN" | cut -d. -f2 | tr '_-' '/+')
    while (( ${#PAYLOAD} % 4 )); do PAYLOAD="$PAYLOAD="; done
    echo "Token claims (compare with the app's federated credential):"
    printf '%s' "$PAYLOAD" | base64 -d | grep -o '"\(iss\|sub\|aud\)":"[^"]*"'
    exit 1
  fi

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
echo "Environment ${TF_ENV:-shared}: tenant $ARM_TENANT_ID, subscription $ARM_SUBSCRIPTION_ID"
