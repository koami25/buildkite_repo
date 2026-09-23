output "environment" {
  value = var.environment
}

output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "storage_account_name" {
  value = module.storage_account.name
}

output "storage_account_id" {
  value = module.storage_account.id
}

output "primary_blob_endpoint" {
  value = module.storage_account.primary_blob_endpoint
}
