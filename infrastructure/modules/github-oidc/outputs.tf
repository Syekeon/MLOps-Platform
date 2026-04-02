output "application_client_id" {
  value = azuread_application.this.client_id
}

output "service_principal_object_id" {
  value = azuread_service_principal.this.object_id
}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "branch_subject" {
  value = local.branch_subject
}
