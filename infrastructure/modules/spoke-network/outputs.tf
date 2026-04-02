output "spoke_vnet_id" {
  value = azurerm_virtual_network.spoke.id
}

output "spoke_vnet_name" {
  value = azurerm_virtual_network.spoke.name
}

output "aml_compute_subnet_id" {
  value = azurerm_subnet.aml_compute.id
}

output "private_endpoints_subnet_id" {
  value = azurerm_subnet.private_endpoints.id
}

output "devops_runner_subnet_id" {
  value = azurerm_subnet.devops_runner.id
}
