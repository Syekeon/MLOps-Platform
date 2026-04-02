output "workload_resource_group_name" {
  value = module.resource_groups.resource_group_name
}

output "spoke_resource_group_name" {
  value = module.spoke_resource_group.resource_group_name
}

output "spoke_vnet_id" {
  value = module.spoke_network.spoke_vnet_id
}

output "spoke_vnet_name" {
  value = module.spoke_network.spoke_vnet_name
}

output "spoke_aml_compute_subnet_id" {
  value = module.spoke_network.aml_compute_subnet_id
}

output "spoke_private_endpoints_subnet_id" {
  value = module.spoke_network.private_endpoints_subnet_id
}

output "spoke_devops_runner_subnet_id" {
  value = module.spoke_network.devops_runner_subnet_id
}

output "endpoint_identity_id" {
  value = module.identities.endpoint_identity_id
}

output "runner_identity_id" {
  value = module.identities.runner_identity_id
}

output "compute_identity_id" {
  value = module.identities.compute_identity_id
}

output "endpoint_identity_principal_id" {
  value = module.identities.endpoint_identity_principal_id
}

output "runner_identity_principal_id" {
  value = module.identities.runner_identity_principal_id
}

output "compute_identity_principal_id" {
  value = module.identities.compute_identity_principal_id
}

output "runner_vm_id" {
  value = module.runner_vm.id
}

output "runner_vm_name" {
  value = module.runner_vm.name
}

output "runner_vm_private_ip_address" {
  value = module.runner_vm.private_ip_address
}

output "log_analytics_workspace_id" {
  value = var.shared_log_analytics_workspace_id
}

output "application_insights_id" {
  value = var.shared_application_insights_id
}

output "storage_account_id" {
  value = module.storage_aml.id
}

output "key_vault_id" {
  value = module.key_vault.id
}

output "acr_id" {
  value = module.acr.id
}

output "aml_workspace_id" {
  value = module.aml_workspace.id
}

output "aml_workspace_principal_id" {
  value = module.aml_workspace.principal_id
}

output "aml_compute_cluster_id" {
  value = module.aml_compute_cluster.id
}

output "aml_compute_cluster_name" {
  value = module.aml_compute_cluster.name
}

output "aml_compute_cluster_principal_id" {
  value = module.aml_compute_cluster.principal_id
}

output "storage_blob_private_endpoint_id" {
  value = module.private_endpoints.storage_blob_private_endpoint_id
}

output "key_vault_private_endpoint_id" {
  value = module.private_endpoints.key_vault_private_endpoint_id
}

output "acr_private_endpoint_id" {
  value = module.private_endpoints.acr_private_endpoint_id
}

output "aml_workspace_private_endpoint_id" {
  value = module.private_endpoints.aml_workspace_private_endpoint_id
}

output "rbac_assignment_ids" {
  value = module.rbac.assignment_ids
}

output "github_oidc_application_client_id" {
  value = try(module.github_oidc[0].application_client_id, null)
}

output "github_oidc_tenant_id" {
  value = try(module.github_oidc[0].tenant_id, null)
}

output "github_oidc_branch_subject" {
  value = try(module.github_oidc[0].branch_subject, null)
}
