locals {
  location_short = lookup({
    southcentralus = "scus"
    northcentralus = "ncus"
    centralus      = "cus"
    eastus         = "eus"
    eastus2        = "eus2"
    westus         = "wus"
    westus2        = "wus2"
    westus3        = "wus3"
  }, var.location, var.location)

  # Naming convention: <type>-<project>-<env>-<region>-<instance>
  resource_group_name  = "rg-${var.project}-${var.environment}-${local.location_short}-${var.instance}"
  storage_account_name = coalesce(var.storage_account_name, "st${var.project}${var.environment}${local.location_short}${var.instance}")

  tags = merge(var.tags, {
    environment = var.environment
    project     = var.project
    managed_by  = "terraform"
  })
}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.tags
}

module "storage_account" {
  source = "./modules/storage-account"

  name                = local.storage_account_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  replication_type           = var.replication_type
  access_tier                = var.access_tier
  network_default_action     = var.network_default_action
  allowed_ip_rules           = var.allowed_ip_rules
  allowed_subnet_ids         = var.allowed_subnet_ids
  blob_versioning_enabled    = var.blob_versioning_enabled
  change_feed_enabled        = var.change_feed_enabled
  blob_soft_delete_days      = var.blob_soft_delete_days
  container_soft_delete_days = var.container_soft_delete_days
  enable_delete_lock         = var.enable_delete_lock
  log_analytics_workspace_id = var.log_analytics_workspace_id

  tags = local.tags
}
