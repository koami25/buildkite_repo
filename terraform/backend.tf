terraform {
  # Partial config: storage account, container and state key come from
  # environments/<env>/backend.hcl at `terraform init -backend-config=...`.
  backend "azurerm" {
    use_oidc         = true
    use_azuread_auth = true
  }
}
