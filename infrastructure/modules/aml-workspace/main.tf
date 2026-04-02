resource "azurerm_machine_learning_workspace" "this" {
  name                          = var.workspace_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  application_insights_id       = var.application_insights_id
  key_vault_id                  = var.key_vault_id
  storage_account_id            = var.storage_account_id
  container_registry_id         = var.container_registry_id
  public_network_access_enabled = !var.enable_private_networking

  identity {
    type = "SystemAssigned"
  }

  managed_network {
    isolation_mode = var.managed_network_isolation_mode
  }

  tags = var.tags
}
