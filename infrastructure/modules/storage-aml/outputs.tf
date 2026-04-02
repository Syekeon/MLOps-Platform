output "id" { value = azurerm_storage_account.this.id }
output "name" { value = azurerm_storage_account.this.name }
output "blob_service_id" { value = "${azurerm_storage_account.this.id}/blobServices/default" }
