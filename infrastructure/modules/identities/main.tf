resource "azurerm_user_assigned_identity" "endpoint" {
  name                = var.endpoint_identity_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "runner" {
  name                = var.runner_identity_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "compute" {
  name                = var.compute_identity_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}
