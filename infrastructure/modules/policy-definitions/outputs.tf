output "ids" {
  value = { for k, v in azurerm_policy_definition.this : k => v.id }
}

output "display_names" {
  value = { for k, v in azurerm_policy_definition.this : k => v.display_name }
}
