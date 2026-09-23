#!/usr/bin/env bash
# Usage: tf.sh <dev|uat|prod> <plan|apply|plan-destroy|destroy>
#   plan          - writes <env>.tfplan, uploads it as an artifact and annotates the build
#   apply         - downloads that exact plan artifact and applies it
#   plan-destroy  - same as plan, but for tearing the environment down
#   destroy       - checks the typed confirmation, then applies the destroy plan
set -euo pipefail

USAGE="usage: tf.sh <dev|uat|prod> <plan|apply|plan-destroy|destroy>"
TF_ENV="${1:?$USAGE}"
ACTION="${2:?$USAGE}"

case "$TF_ENV" in dev|uat|prod) ;; *) echo "Unknown environment: $TF_ENV"; exit 1 ;; esac
case "$ACTION" in plan|apply|plan-destroy|destroy) ;; *) echo "Unknown action: $ACTION"; exit 1 ;; esac
export TF_ENV

if [[ "$ACTION" == "destroy" ]]; then
  # The confirm block asks the approver to type the environment name
  CONFIRM=$(buildkite-agent meta-data get "confirm-destroy-$TF_ENV" 2>/dev/null || true)
  if [[ "$CONFIRM" != "$TF_ENV" ]]; then
    echo "Destroy of $TF_ENV not confirmed (typed '$CONFIRM', expected '$TF_ENV'). Aborting."
    exit 1
  fi
fi

source .buildkite/scripts/install-terraform.sh
source .buildkite/scripts/azure-login.sh

TF="terraform -chdir=terraform"
ENV_DIR="environments/$TF_ENV"

case "$ACTION" in
  plan|apply)             PLAN_FILE="$TF_ENV.tfplan";         PLAN_ARGS=() ;;
  plan-destroy|destroy)   PLAN_FILE="$TF_ENV.destroy.tfplan"; PLAN_ARGS=(-destroy) ;;
esac

echo "--- :terraform: init ($TF_ENV)"
$TF init -input=false -reconfigure -lockfile=readonly \
  -backend-config="$ENV_DIR/backend.hcl"

if [[ "$ACTION" == plan* ]]; then
  echo "--- :terraform: $ACTION ($TF_ENV)"
  $TF plan -input=false -lock-timeout=5m ${PLAN_ARGS[@]+"${PLAN_ARGS[@]}"} \
    -var-file="$ENV_DIR/terraform.tfvars" \
    -out="$PLAN_FILE"

  buildkite-agent artifact upload "terraform/$PLAN_FILE"

  # Show the plan on the build page
  STYLE=info
  if [[ "$ACTION" == "plan-destroy" ]]; then STYLE=error; fi
  PLAN_TEXT=$($TF show -no-color "$PLAN_FILE" | head -c 60000)
  SUMMARY=$(printf '%s\n' "$PLAN_TEXT" | grep -E '^(Plan:|No changes)' | head -1 || true)
  printf '<details><summary><b>%s %s</b>: %s</summary>\n\n```\n%s\n```\n</details>\n' \
    "$TF_ENV" "$ACTION" "${SUMMARY:-see log}" "$PLAN_TEXT" \
    | buildkite-agent annotate --context "$ACTION-$TF_ENV" --style "$STYLE"
else
  echo "--- :terraform: $ACTION ($TF_ENV)"
  buildkite-agent artifact download "terraform/$PLAN_FILE" .
  $TF apply -input=false -lock-timeout=5m "$PLAN_FILE"
  if [[ "$ACTION" == "apply" ]]; then
    $TF output
  fi
fi
