# Azure Storage Account – Terraform + Buildkite

Deploys a hardened Azure Storage Account to **dev → uat → prod** with Terraform, run by Buildkite using OIDC (no stored passwords).

## Layout

```
buildkite.yaml                      # pipeline definition
.buildkite/scripts/
  install-terraform.sh              # downloads the pinned terraform version
  azure-login.sh                    # Buildkite OIDC -> Azure (ARM_* env vars)
  tf-validate.sh                    # fmt + validate (no Azure access)
  tf.sh <env> <plan|apply>          # init/plan/apply for one environment
terraform/
  main.tf, variables.tf, outputs.tf # root: naming, resource group, module call
  providers.tf, backend.tf          # azurerm provider, remote state (partial)
  modules/storage-account/          # reusable hardened storage account
  environments/<env>/
    terraform.tfvars                # environment settings
    backend.hcl                     # where that environment's state lives
```

## Pipeline flow

Environments run strictly in order. **Nothing is applied without manual approval.**

```
validate → plan dev  → APPROVE → apply dev
         → plan uat  → APPROVE → apply uat
         → plan prod → APPROVE + change ticket → apply prod
```

| Branch | What runs |
|---|---|
| `main` | the full flow above |
| any other branch / PR | validate, then plan dev → uat → prod (approvals and applies are skipped, nothing is changed) |

uat does not start until dev is applied, and prod does not start until uat is applied. Each apply uses the exact plan file shown in the approval step (plans appear as annotations on the build page). Applies per environment never run in parallel.

## Environments

| | dev | uat | prod |
|---|---|---|---|
| Resource group | `rg-bkdemo-dev-scus-01` | `rg-bkdemo-uat-scus-01` | `rg-bkdemo-prod-scus-01` |
| Storage account | `stbkdemodevscus01` | `stbkdemouatscus01` | `stbkdemoprodscus01` |
| Replication | LRS | ZRS | GZRS |
| Soft delete | 7 days | 14 days | 30 days |
| Delete lock | no | no | yes |

All accounts: TLS 1.2+, HTTPS only, no anonymous blob access, shared keys disabled (Entra ID only), infrastructure encryption, blob versioning.

## Buildkite secrets

Set in the cluster's **Secrets**. An `_<ENV>` suffixed secret overrides the shared one for that environment.

| Secret | Required | Example override |
|---|---|---|
| `AZURE_TENANT_ID` | yes | – |
| `AZURE_CLIENT_ID` | yes (managed identity client ID) | `AZURE_CLIENT_ID_PROD` |
| `AZURE_SUBSCRIPTION_ID` | recommended | `AZURE_SUBSCRIPTION_ID_PROD` |

## Azure setup (per managed identity)

1. **Federated credential** on the managed identity:
   issuer `https://agent.buildkite.com`, subject = Buildkite **cluster UUID**, audience `api://AzureADTokenExchange`.
2. **Roles**
   - `Contributor` on the target subscription
   - `Storage Blob Data Contributor` on the state storage account `sttofustatefilessanddev`
   - prod only: `User Access Administrator` or `Owner` (needed to create the delete lock)

## Making a change

1. Edit `terraform/` on a branch and push; check the plan annotations.
2. Merge to `main`; approve uat, then prod, in Buildkite.

Local checks: `terraform -chdir=terraform fmt -recursive && terraform -chdir=terraform validate`.
