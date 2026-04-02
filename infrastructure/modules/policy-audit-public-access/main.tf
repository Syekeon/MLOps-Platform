resource "azurerm_policy_definition" "this" {
  name         = var.definition_name
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = var.display_name
  description  = var.description

  metadata = jsonencode({
    category = "Network"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = var.resource_type
        },
        {
          field     = var.public_access_alias
          notEquals = "Disabled"
        }
      ]
    }
    then = {
      effect = "audit"
    }
  })
}

resource "azurerm_resource_group_policy_assignment" "this" {
  name                 = "audit-public-${var.assignment_suffix}"
  resource_group_id    = var.scope_id
  policy_definition_id = azurerm_policy_definition.this.id
  display_name         = var.display_name
}
