#!/usr/bin/env bash
# Usage: tf.sh <dev|uat|prod> <plan|apply>
#   plan  - writes <env>.tfplan, uploads it as an artifact and annotates the build
#   apply - downloads that exact plan artifact and applies it
set -euo pipefail

TF_ENV="${1:?usage: tf.sh <dev|uat|prod> <plan|apply>}"
ACTION="${2:?usage: tf.sh <dev|uat|prod> <plan|apply>}"

case "$TF_ENV" in dev|uat|prod) ;; *) echo "Unknown environment: $TF_ENV"; exit 1 ;; esac
case "$ACTION" in plan|apply) ;; *) echo "Unknown action: $ACTION"; exit 1 ;; esac
export TF_ENV

source .buildkite/scripts/install-terraform.sh
source .buildkite/scripts/azure-login.sh

TF="terraform -chdir=terraform"
ENV_DIR="environments/$TF_ENV"
PLAN_FILE="$TF_ENV.tfplan"

echo "--- :terraform: init ($TF_ENV)"
$TF init -input=false -reconfigure -lockfile=readonly \
  -backend-config="$ENV_DIR/backend.hcl"

if [[ "$ACTION" == "plan" ]]; then
  echo "--- :terraform: plan ($TF_ENV)"
  $TF plan -input=false -lock-timeout=5m \
    -var-file="$ENV_DIR/terraform.tfvars" \
    -out="$PLAN_FILE"

  buildkite-agent artifact upload "terraform/$PLAN_FILE"

  # Show the plan on the build page
  PLAN_TEXT=$($TF show -no-color "$PLAN_FILE" | head -c 60000)
  SUMMARY=$(printf '%s\n' "$PLAN_TEXT" | grep -E '^(Plan:|No changes)' | head -1 || true)
  printf '<details><summary><b>%s</b>: %s</summary>\n\n```\n%s\n```\n</details>\n' \
    "$TF_ENV" "${SUMMARY:-see log}" "$PLAN_TEXT" \
    | buildkite-agent annotate --context "plan-$TF_ENV" --style info
else
  echo "--- :terraform: apply ($TF_ENV)"
  buildkite-agent artifact download "terraform/$PLAN_FILE" .
  $TF apply -input=false -lock-timeout=5m "$PLAN_FILE"
  $TF output
fi
