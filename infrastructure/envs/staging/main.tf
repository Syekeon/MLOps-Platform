module "governance" {
  source      = "../../modules/governance"
  workload    = var.workload
  environment = var.environment
  owner       = var.tag_owner
  cost_center = var.tag_cost_center
}

locals {
  policy_definitions = {
    storage_public_access = {
      name         = "audit-storage-public-access-disabled"
      display_name = "Audit Storage public network access disabled"
    }
    keyvault_public_access = {
      name         = "audit-keyvault-public-access-disabled"
      display_name = "Audit Key Vault public network access disabled"
    }
    acr_public_access = {
      name         = "audit-acr-public-access-disabled"
      display_name = "Audit ACR public network access disabled"
    }
    aml_workspace_public_access = {
      name         = "audit-aml-workspace-public-access-disabled"
      display_name = "Audit AML Workspace public network access disabled"
    }
    runner_vm_sizes = {
      name         = "audit-allowed-vm-sizes"
      display_name = "Audit allowed VM sizes for workload VMs"
    }
    aml_compute_sizes = {
      name         = "audit-allowed-aml-compute-sizes"
      display_name = "Audit allowed AML compute sizes"
    }
    online_deployment_sizes = {
      name         = "audit-allowed-aml-online-deployment-sizes"
      display_name = "Audit allowed AML online deployment sizes"
    }
  }

  policy_definition_ids = {
    for k, v in local.policy_definitions :
    k => "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/policyDefinitions/${v.name}"
  }

  private_dns_zone_names = {
    api_azureml_ms        = "privatelink.api.azureml.ms"
    notebooks_azure_net   = "privatelink.notebooks.azure.net"
    blob_core_windows_net = "privatelink.blob.core.windows.net"
    file_core_windows_net = "privatelink.file.core.windows.net"
    dfs_core_windows_net  = "privatelink.dfs.core.windows.net"
    vaultcore_azure_net   = "privatelink.vaultcore.azure.net"
    azurecr_io            = "privatelink.azurecr.io"
  }
}

module "naming" {
  source            = "../../modules/naming"
  workload          = var.workload
  environment_short = var.environment_short
  location          = var.location
  instance          = var.instance
}

module "resource_groups" {
  source   = "../../modules/resource-groups"
  rg_name  = var.rg_workload_name
  location = var.location
  tags     = module.governance.tags
}

module "spoke_resource_group" {
  source   = "../../modules/resource-groups"
  rg_name  = var.rg_infra_name
  location = var.location
  tags     = module.governance.tags
}

module "spoke_network" {
  source                        = "../../modules/spoke-network"
  resource_group_name           = module.spoke_resource_group.resource_group_name
  location                      = var.location
  spoke_vnet_name               = var.spoke_vnet_name
  spoke_vnet_cidr               = var.spoke_vnet_cidr
  aml_compute_subnet_name       = var.spoke_aml_compute_subnet_name
  aml_compute_subnet_cidr       = var.spoke_aml_compute_subnet_cidr
  private_endpoints_subnet_name = var.spoke_private_endpoints_subnet_name
  private_endpoints_subnet_cidr = var.spoke_private_endpoints_subnet_cidr
  devops_runner_subnet_name     = var.spoke_devops_runner_subnet_name
  devops_runner_subnet_cidr     = var.spoke_devops_runner_subnet_cidr
  tags                          = module.governance.tags
}

module "route_tables" {
  source                  = "../../modules/route-tables"
  resource_group_name     = module.spoke_resource_group.resource_group_name
  location                = var.location
  route_table_name        = "udr-${var.workload}-${var.environment_short}-${var.location_short}-${var.instance}"
  next_hop_ip_address     = var.hub_firewall_private_ip
  aml_compute_subnet_id   = module.spoke_network.aml_compute_subnet_id
  devops_runner_subnet_id = module.spoke_network.devops_runner_subnet_id
  tags                    = module.governance.tags
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-${var.spoke_vnet_name}-to-${var.hub_vnet_name}"
  resource_group_name       = module.spoke_resource_group.resource_group_name
  virtual_network_name      = module.spoke_network.spoke_vnet_name
  remote_virtual_network_id = var.hub_vnet_id
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "peer-${var.hub_vnet_name}-to-${var.spoke_vnet_name}"
  resource_group_name       = var.hub_resource_group_name
  virtual_network_name      = var.hub_vnet_name
  remote_virtual_network_id = module.spoke_network.spoke_vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke_api_azureml_ms" {
  name                  = "link-spoke-${replace(local.private_dns_zone_names.api_azureml_ms, ".", "-")}"
  resource_group_name   = var.hub_resource_group_name
  private_dns_zone_name = local.private_dns_zone_names.api_azureml_ms
  virtual_network_id    = module.spoke_network.spoke_vnet_id
  registration_enabled  = false
  tags                  = module.governance.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke_notebooks_azure_net" {
  name                  = "link-spoke-${replace(local.private_dns_zone_names.notebooks_azure_net, ".", "-")}"
  resource_group_name   = var.hub_resource_group_name
  private_dns_zone_name = local.private_dns_zone_names.notebooks_azure_net
  virtual_network_id    = module.spoke_network.spoke_vnet_id
  registration_enabled  = false
  tags                  = module.governance.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke_blob_core_windows_net" {
  name                  = "link-spoke-${replace(local.private_dns_zone_names.blob_core_windows_net, ".", "-")}"
  resource_group_name   = var.hub_resource_group_name
  private_dns_zone_name = local.private_dns_zone_names.blob_core_windows_net
  virtual_network_id    = module.spoke_network.spoke_vnet_id
  registration_enabled  = false
  tags                  = module.governance.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke_file_core_windows_net" {
  name                  = "link-spoke-${replace(local.private_dns_zone_names.file_core_windows_net, ".", "-")}"
  resource_group_name   = var.hub_resource_group_name
  private_dns_zone_name = local.private_dns_zone_names.file_core_windows_net
  virtual_network_id    = module.spoke_network.spoke_vnet_id
  registration_enabled  = false
  tags                  = module.governance.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke_dfs_core_windows_net" {
  name                  = "link-spoke-${replace(local.private_dns_zone_names.dfs_core_windows_net, ".", "-")}"
  resource_group_name   = var.hub_resource_group_name
  private_dns_zone_name = local.private_dns_zone_names.dfs_core_windows_net
  virtual_network_id    = module.spoke_network.spoke_vnet_id
  registration_enabled  = false
  tags                  = module.governance.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke_vaultcore_azure_net" {
  name                  = "link-spoke-${replace(local.private_dns_zone_names.vaultcore_azure_net, ".", "-")}"
  resource_group_name   = var.hub_resource_group_name
  private_dns_zone_name = local.private_dns_zone_names.vaultcore_azure_net
  virtual_network_id    = module.spoke_network.spoke_vnet_id
  registration_enabled  = false
  tags                  = module.governance.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke_azurecr_io" {
  name                  = "link-spoke-${replace(local.private_dns_zone_names.azurecr_io, ".", "-")}"
  resource_group_name   = var.hub_resource_group_name
  private_dns_zone_name = local.private_dns_zone_names.azurecr_io
  virtual_network_id    = module.spoke_network.spoke_vnet_id
  registration_enabled  = false
  tags                  = module.governance.tags
}

module "policy_require_tags_workload" {
  source        = "../../modules/policy-require-tags"
  scope_id      = module.resource_groups.resource_group_id
  required_tags = ["owner", "cost_center", "project", "environment"]
}

module "policy_require_tags_spoke" {
  source        = "../../modules/policy-require-tags"
  scope_id      = module.spoke_resource_group.resource_group_id
  required_tags = ["owner", "cost_center", "project", "environment"]
}

module "policy_definitions" {
  source = "../../modules/policy-definitions"
}

module "policy_assign_storage_public_access" {
  source               = "../../modules/policy-rg-assignment"
  assignment_name      = "audit-public-storage"
  scope_id             = module.resource_groups.resource_group_id
  policy_definition_id = local.policy_definition_ids["storage_public_access"]
  display_name         = local.policy_definitions["storage_public_access"].display_name
  depends_on           = [module.policy_definitions]
}

module "policy_assign_keyvault_public_access" {
  source               = "../../modules/policy-rg-assignment"
  assignment_name      = "audit-public-keyvault"
  scope_id             = module.resource_groups.resource_group_id
  policy_definition_id = local.policy_definition_ids["keyvault_public_access"]
  display_name         = local.policy_definitions["keyvault_public_access"].display_name
  depends_on           = [module.policy_definitions]
}

module "policy_assign_acr_public_access" {
  source               = "../../modules/policy-rg-assignment"
  assignment_name      = "audit-public-acr"
  scope_id             = module.resource_groups.resource_group_id
  policy_definition_id = local.policy_definition_ids["acr_public_access"]
  display_name         = local.policy_definitions["acr_public_access"].display_name
  depends_on           = [module.policy_definitions]
}

module "policy_assign_aml_workspace_public_access" {
  source               = "../../modules/policy-rg-assignment"
  assignment_name      = "audit-public-amlworkspace"
  scope_id             = module.resource_groups.resource_group_id
  policy_definition_id = local.policy_definition_ids["aml_workspace_public_access"]
  display_name         = local.policy_definitions["aml_workspace_public_access"].display_name
  depends_on           = [module.policy_definitions]
}

module "policy_assign_runner_vm_sizes" {
  source               = "../../modules/policy-rg-assignment"
  assignment_name      = "audit-size-vm"
  scope_id             = module.resource_groups.resource_group_id
  policy_definition_id = local.policy_definition_ids["runner_vm_sizes"]
  display_name         = local.policy_definitions["runner_vm_sizes"].display_name
  depends_on           = [module.policy_definitions]
  parameters_json = jsonencode({
    allowedSizes = {
      value = ["Standard_D2s_v3"]
    }
  })
}

module "policy_assign_aml_compute_sizes" {
  source               = "../../modules/policy-rg-assignment"
  assignment_name      = "audit-size-amlcompute"
  scope_id             = module.resource_groups.resource_group_id
  policy_definition_id = local.policy_definition_ids["aml_compute_sizes"]
  display_name         = local.policy_definitions["aml_compute_sizes"].display_name
  depends_on           = [module.policy_definitions]
  parameters_json = jsonencode({
    allowedSizes = {
      value = ["Standard_DS2_v2"]
    }
  })
}

module "policy_assign_online_deployment_sizes" {
  source               = "../../modules/policy-rg-assignment"
  assignment_name      = "audit-size-onlinedeployment"
  scope_id             = module.resource_groups.resource_group_id
  policy_definition_id = local.policy_definition_ids["online_deployment_sizes"]
  display_name         = local.policy_definitions["online_deployment_sizes"].display_name
  depends_on           = [module.policy_definitions]
  parameters_json = jsonencode({
    allowedSizes = {
      value = ["Standard_E2s_v3", "Standard_DS2_v2"]
    }
  })
}

module "github_oidc" {
  count                  = var.github_owner != "" && var.github_repository != "" ? 1 : 0
  source                 = "../../modules/github-oidc"
  application_display_name = "app-${var.workload}-${var.environment_short}-github-oidc-${var.instance}"
  github_owner           = var.github_owner
  github_repository      = var.github_repository
  github_main_branch     = var.github_main_branch
  scope                  = module.resource_groups.resource_group_id
  role_definition_name   = var.github_oidc_role_definition_name
}

module "identities" {
  source                = "../../modules/identities"
  resource_group_name   = module.resource_groups.resource_group_name
  location              = var.location
  endpoint_identity_name = var.endpoint_identity_name
  runner_identity_name   = var.runner_identity_name
  compute_identity_name  = var.compute_identity_name
  tags                  = module.governance.tags
}

module "storage_aml" {
  source              = "../../modules/storage-aml"
  resource_group_name = module.resource_groups.resource_group_name
  location            = var.location
  storage_account_name = module.naming.storage_account_name
  enable_private_networking = var.enable_private_networking
  tags                = module.governance.tags
}

module "key_vault" {
  source               = "../../modules/key-vault"
  resource_group_name  = module.resource_groups.resource_group_name
  location             = var.location
  key_vault_name       = module.naming.key_vault_name
  enable_private_networking = var.enable_private_networking
  tags                 = module.governance.tags
}

module "acr" {
  source              = "../../modules/acr"
  resource_group_name = module.resource_groups.resource_group_name
  location            = var.location
  acr_name            = module.naming.acr_name
  enable_private_networking = var.enable_private_networking
  tags                = module.governance.tags
}

module "aml_workspace" {
  source                = "../../modules/aml-workspace"
  resource_group_name   = module.resource_groups.resource_group_name
  location              = var.location
  workspace_name        = module.naming.aml_workspace_name
  application_insights_id = var.shared_application_insights_id
  key_vault_id          = module.key_vault.id
  storage_account_id    = module.storage_aml.id
  container_registry_id = module.acr.id
  enable_private_networking = var.enable_private_networking
  managed_network_isolation_mode = var.managed_network_isolation_mode
  tags                  = module.governance.tags
}

module "rbac" {
  source                        = "../../modules/rbac"
  resource_group_id             = module.resource_groups.resource_group_id
  storage_account_id            = module.storage_aml.id
  key_vault_id                  = module.key_vault.id
  acr_id                        = module.acr.id
  aml_workspace_principal_id    = module.aml_workspace.principal_id
  endpoint_identity_principal_id = module.identities.endpoint_identity_principal_id
  runner_identity_principal_id   = module.identities.runner_identity_principal_id
  compute_identity_principal_id  = module.identities.compute_identity_principal_id
}

module "runner_vm" {
  source                    = "../../modules/runner-vm"
  resource_group_name       = module.resource_groups.resource_group_name
  location                  = var.location
  vm_name                   = module.naming.runner_vm_name
  nic_name                  = module.naming.runner_nic_name
  subnet_id                 = module.spoke_network.devops_runner_subnet_id
  admin_username            = var.runner_admin_username
  admin_password            = var.runner_admin_password
  vm_size                   = var.runner_vm_size
  user_assigned_identity_id = module.identities.runner_identity_id
  tags                      = module.governance.tags
}

module "aml_compute_cluster" {
  source              = "../../modules/aml-compute-cluster"
  resource_group_name = module.resource_groups.resource_group_name
  location            = var.location
  workspace_id        = module.aml_workspace.id
  compute_name        = var.aml_compute_name
  subnet_id           = var.managed_network_isolation_mode == "Disabled" ? module.spoke_network.aml_compute_subnet_id : null
  user_assigned_identity_id = module.identities.compute_identity_id
  vm_size             = var.aml_compute_vm_size
  min_instances       = var.aml_compute_min_instances
  max_instances       = var.aml_compute_max_instances
  enable_node_public_ip = var.managed_network_isolation_mode == "Disabled" ? false : true
  ssh_public_access_enabled = var.managed_network_isolation_mode == "Disabled" ? false : true
  admin_username      = var.runner_admin_username
  admin_password      = var.runner_admin_password
  tags                = module.governance.tags
}

module "private_endpoints" {
  source                                      = "../../modules/private-endpoints"
  resource_group_name                         = module.resource_groups.resource_group_name
  location                                    = var.location
  private_endpoints_subnet_id                 = module.spoke_network.private_endpoints_subnet_id
  enable_private_networking                   = var.enable_private_networking
  storage_account_id                          = module.storage_aml.id
  key_vault_id                                = module.key_vault.id
  acr_id                                      = module.acr.id
  aml_workspace_id                            = module.aml_workspace.id
  private_dns_zone_id_blob_core_windows_net   = var.private_dns_zone_id_blob_core_windows_net
  private_dns_zone_id_file_core_windows_net   = var.private_dns_zone_id_file_core_windows_net
  private_dns_zone_id_dfs_core_windows_net    = var.private_dns_zone_id_dfs_core_windows_net
  private_dns_zone_id_vaultcore_azure_net     = var.private_dns_zone_id_vaultcore_azure_net
  private_dns_zone_id_azurecr_io              = var.private_dns_zone_id_azurecr_io
  private_dns_zone_id_api_azureml_ms          = var.private_dns_zone_id_api_azureml_ms
  private_dns_zone_id_notebooks_azure_net     = var.private_dns_zone_id_notebooks_azure_net
  tags                                        = module.governance.tags
}

module "diag_storage" {
  source                     = "../../modules/diagnostic-settings"
  name                       = "diag-storage-to-law"
  target_resource_id         = module.storage_aml.blob_service_id
  log_analytics_workspace_id = var.shared_log_analytics_workspace_id
  log_category_groups        = []
  log_categories             = ["StorageRead", "StorageWrite", "StorageDelete"]
  metric_categories          = ["Capacity", "Transaction"]
}

module "diag_key_vault" {
  source                     = "../../modules/diagnostic-settings"
  name                       = "diag-keyvault-to-law"
  target_resource_id         = module.key_vault.id
  log_analytics_workspace_id = var.shared_log_analytics_workspace_id
}

module "diag_acr" {
  source                     = "../../modules/diagnostic-settings"
  name                       = "diag-acr-to-law"
  target_resource_id         = module.acr.id
  log_analytics_workspace_id = var.shared_log_analytics_workspace_id
}

module "diag_aml_workspace" {
  source                     = "../../modules/diagnostic-settings"
  name                       = "diag-amlworkspace-to-law"
  target_resource_id         = module.aml_workspace.id
  log_analytics_workspace_id = var.shared_log_analytics_workspace_id
}

module "diag_spoke_vnet" {
  source                     = "../../modules/diagnostic-settings"
  name                       = "diag-spoke-vnet-to-law"
  target_resource_id         = module.spoke_network.spoke_vnet_id
  log_analytics_workspace_id = var.shared_log_analytics_workspace_id
}
