#!/usr/bin/env bash
# Static checks that need no Azure credentials.
set -euo pipefail

source .buildkite/scripts/install-terraform.sh

terraform -chdir=terraform fmt -check -recursive -diff
terraform -chdir=terraform init -backend=false -input=false -lockfile=readonly
terraform -chdir=terraform validate
