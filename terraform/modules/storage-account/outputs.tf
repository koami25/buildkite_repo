output "id" {
  value = azurerm_storage_account.this.id
}

output "name" {
  value = azurerm_storage_account.this.name
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.this.primary_blob_endpoint
}

output "principal_id" {
  description = "Object ID of the account's system-assigned identity."
  value       = azurerm_storage_account.this.identity[0].principal_id
}
