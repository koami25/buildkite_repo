#!/usr/bin/env bash
# Generates and uploads destroy steps for the environment picked in destroy.yaml.
set -euo pipefail

if [[ "${BUILDKITE_BRANCH:-}" != "main" ]]; then
  echo "Destroy only runs from main (this build is on '${BUILDKITE_BRANCH:-unknown}')."
  exit 1
fi

TARGET=$(buildkite-agent meta-data get destroy-target)
case "$TARGET" in
  dev|uat|prod) ENVS="$TARGET" ;;
  all)          ENVS="prod uat dev" ;;   # reverse of the deploy order
  *) echo "Unknown destroy target: $TARGET"; exit 1 ;;
esac

PIPELINE="steps:"
PREVIOUS="destroy-generate"

for env in $ENVS; do
  EXTRA_FIELD=""
  if [[ "$env" == "prod" ]]; then
    EXTRA_FIELD='
          - text: "Change ticket"
            key: "destroy-prod-change-ticket"
            required: true'
  fi

  PIPELINE+="
  - label: \":terraform: plan destroy $env\"
    key: \"plan-destroy-$env\"
    depends_on: \"$PREVIOUS\"
    command: \"bash .buildkite/scripts/tf.sh $env plan-destroy\"
    timeout_in_minutes: 20

  - block: \":rotating_light: Confirm DESTROY of $env\"
    key: \"confirm-destroy-$env-block\"
    depends_on: \"plan-destroy-$env\"
    prompt: \"Review the $env plan-destroy annotation. This deletes every resource in $env.\"
    fields:
          - text: \"Type '$env' to confirm\"
            key: \"confirm-destroy-$env\"
            required: true$EXTRA_FIELD

  - label: \":boom: destroy $env\"
    key: \"destroy-$env\"
    depends_on: \"confirm-destroy-$env-block\"
    command: \"bash .buildkite/scripts/tf.sh $env destroy\"
    timeout_in_minutes: 30
    concurrency: 1
    concurrency_group: \"bkdemo-storage/$env\"
"
  PREVIOUS="destroy-$env"
done

echo "$PIPELINE"
# --no-interpolation: the generated YAML is final, nothing to substitute
printf '%s\n' "$PIPELINE" | buildkite-agent pipeline upload --no-interpolation
