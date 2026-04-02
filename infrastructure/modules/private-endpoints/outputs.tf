output "storage_blob_private_endpoint_id" {
  value = try(azurerm_private_endpoint.storage_blob[0].id, null)
}

output "key_vault_private_endpoint_id" {
  value = try(azurerm_private_endpoint.key_vault[0].id, null)
}

output "acr_private_endpoint_id" {
  value = try(azurerm_private_endpoint.acr_registry[0].id, null)
}

output "aml_workspace_private_endpoint_id" {
  value = try(azurerm_private_endpoint.aml_workspace[0].id, null)
}
