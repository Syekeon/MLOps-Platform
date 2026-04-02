resource "azurerm_storage_account" "this" {
  name                            = var.storage_account_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  public_network_access_enabled   = !var.enable_private_networking
  # Azure ML workspace default storage cannot use HNS-enabled accounts.
  is_hns_enabled                  = false
  tags                            = var.tags
}
