resource "azurerm_resource_group_policy_assignment" "this" {
  name                 = var.assignment_name
  resource_group_id    = var.scope_id
  policy_definition_id = var.policy_definition_id
  display_name         = var.display_name
  parameters           = var.parameters_json
}
