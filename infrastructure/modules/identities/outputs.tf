output "endpoint_identity_id" { value = azurerm_user_assigned_identity.endpoint.id }
output "endpoint_identity_principal_id" { value = azurerm_user_assigned_identity.endpoint.principal_id }
output "runner_identity_id" { value = azurerm_user_assigned_identity.runner.id }
output "runner_identity_principal_id" { value = azurerm_user_assigned_identity.runner.principal_id }
output "compute_identity_id" { value = azurerm_user_assigned_identity.compute.id }
output "compute_identity_principal_id" { value = azurerm_user_assigned_identity.compute.principal_id }
