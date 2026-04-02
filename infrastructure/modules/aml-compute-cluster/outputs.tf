output "id" {
  value = jsondecode(azurerm_resource_group_template_deployment.this.output_content).id.value
}

output "name" {
  value = jsondecode(azurerm_resource_group_template_deployment.this.output_content).name.value
}

output "principal_id" {
  value = try(jsondecode(azurerm_resource_group_template_deployment.this.output_content).principalId.value, null)
}
