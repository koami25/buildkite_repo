output "resource_group_name" {
  value = azurerm_resource_group.buildkitedemo.name
}

output "storage_account_name" {
  value = azurerm_storage_account.buildkitedemo.name
}

output "storage_account_id" {
  value = azurerm_storage_account.buildkitedemo.id
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.buildkitedemo.primary_blob_endpoint
}
