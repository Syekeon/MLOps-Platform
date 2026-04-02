output "id" { value = azurerm_linux_virtual_machine.this.id }
output "name" { value = azurerm_linux_virtual_machine.this.name }
output "private_ip_address" { value = azurerm_network_interface.this.private_ip_address }
output "network_interface_id" { value = azurerm_network_interface.this.id }
