resource "azurerm_resource_group" "buildkitedemo" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_storage_account" "buildkitedemo" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.buildkitedemo.name
  location                 = azurerm_resource_group.buildkitedemo.location
  account_kind             = "StorageV2"
  account_tier             = var.account_tier
  account_replication_type = var.replication_type

  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  blob_properties {
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  tags = var.tags
}
