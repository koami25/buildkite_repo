terraform {
  backend "azurerm" {
    resource_group_name  = "rg_charm_online_sand"
    storage_account_name = "sttofustatefilessanddev"
    container_name       = "buildkitedemo"
    key                  = "storage-buildkitedemo.tfstate"

    # Auth via Buildkite OIDC (ARM_CLIENT_ID, ARM_TENANT_ID, ARM_OIDC_TOKEN)
    use_oidc         = true
    use_azuread_auth = true
  }
}
