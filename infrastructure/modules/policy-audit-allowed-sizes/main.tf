resource "azurerm_policy_definition" "this" {
  name         = var.definition_name
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = var.display_name
  description  = var.description

  metadata = jsonencode({
    category = "Cost Management"
  })

  parameters = jsonencode({
    allowedSizes = {
      type = "Array"
      metadata = {
        displayName = "Allowed sizes"
      }
    }
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = var.resource_type
        },
        {
          field = var.size_alias
          notIn = "[parameters('allowedSizes')]"
        }
      ]
    }
    then = {
      effect = "audit"
    }
  })
}

resource "azurerm_resource_group_policy_assignment" "this" {
  name                 = "audit-size-${var.assignment_suffix}"
  resource_group_id    = var.scope_id
  policy_definition_id = azurerm_policy_definition.this.id
  display_name         = var.display_name

  parameters = jsonencode({
    allowedSizes = {
      value = var.allowed_sizes
    }
  })
}
