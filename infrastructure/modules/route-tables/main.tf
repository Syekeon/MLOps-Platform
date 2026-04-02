resource "azurerm_route_table" "spoke" {
  name                = var.route_table_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  route {
    name                   = "default-to-nva"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.next_hop_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "aml_compute" {
  subnet_id      = var.aml_compute_subnet_id
  route_table_id = azurerm_route_table.spoke.id
}

resource "azurerm_subnet_route_table_association" "devops_runner" {
  subnet_id      = var.devops_runner_subnet_id
  route_table_id = azurerm_route_table.spoke.id
}
