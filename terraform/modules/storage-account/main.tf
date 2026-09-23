resource "azurerm_storage_account" "this" {
  name                     = var.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_kind             = "StorageV2"
  account_tier             = var.account_tier
  account_replication_type = var.replication_type
  access_tier              = var.access_tier

  # Security baseline
  https_traffic_only_enabled        = true
  min_tls_version                   = "TLS1_2"
  allow_nested_items_to_be_public   = false
  cross_tenant_replication_enabled  = false
  shared_access_key_enabled         = var.shared_access_key_enabled
  default_to_oauth_authentication   = true
  public_network_access_enabled     = var.public_network_access_enabled
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled

  identity {
    type = "SystemAssigned"
  }

  blob_properties {
    versioning_enabled  = var.blob_versioning_enabled
    change_feed_enabled = var.change_feed_enabled

    delete_retention_policy {
      days = var.blob_soft_delete_days
    }
    container_delete_retention_policy {
      days = var.container_soft_delete_days
    }
  }

  network_rules {
    default_action             = var.network_default_action
    bypass                     = ["AzureServices"]
    ip_rules                   = var.allowed_ip_rules
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

  tags = var.tags
}

resource "azurerm_management_lock" "no_delete" {
  count = var.enable_delete_lock ? 1 : 0

  name       = "lock-${var.name}-nodelete"
  scope      = azurerm_storage_account.this.id
  lock_level = "CanNotDelete"
  notes      = "Managed by Terraform. Remove via code, not the portal."
}

resource "azurerm_monitor_diagnostic_setting" "blob" {
  count = var.log_analytics_workspace_id == null ? 0 : 1

  name                       = "diag-${var.name}-blob"
  target_resource_id         = "${azurerm_storage_account.this.id}/blobServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }
}
