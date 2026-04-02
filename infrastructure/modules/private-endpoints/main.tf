resource "azurerm_private_endpoint" "storage_blob" {
  count               = var.enable_private_networking ? 1 : 0
  name                = "pep-storage-blob"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-storage-blob"
    private_connection_resource_id = var.storage_account_id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdzg-storage-blob"
    private_dns_zone_ids = [var.private_dns_zone_id_blob_core_windows_net]
  }
}

resource "azurerm_private_endpoint" "storage_file" {
  count               = var.enable_private_networking ? 1 : 0
  name                = "pep-storage-file"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-storage-file"
    private_connection_resource_id = var.storage_account_id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdzg-storage-file"
    private_dns_zone_ids = [var.private_dns_zone_id_file_core_windows_net]
  }
}

resource "azurerm_private_endpoint" "key_vault" {
  count               = var.enable_private_networking ? 1 : 0
  name                = "pep-key-vault"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-key-vault"
    private_connection_resource_id = var.key_vault_id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdzg-key-vault"
    private_dns_zone_ids = [var.private_dns_zone_id_vaultcore_azure_net]
  }
}

resource "azurerm_private_endpoint" "acr_registry" {
  count               = var.enable_private_networking ? 1 : 0
  name                = "pep-acr-registry"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-acr-registry"
    private_connection_resource_id = var.acr_id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdzg-acr-registry"
    private_dns_zone_ids = [var.private_dns_zone_id_azurecr_io]
  }
}

resource "azurerm_private_endpoint" "aml_workspace" {
  count               = var.enable_private_networking ? 1 : 0
  name                = "pep-aml-workspace"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-aml-workspace"
    private_connection_resource_id = var.aml_workspace_id
    subresource_names              = ["amlworkspace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdzg-aml-workspace"
    private_dns_zone_ids = [
      var.private_dns_zone_id_api_azureml_ms,
      var.private_dns_zone_id_notebooks_azure_net,
    ]
  }
}
