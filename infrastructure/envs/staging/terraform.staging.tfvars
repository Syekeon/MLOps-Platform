subscription_id                           = "e19e0ebc-a9ed-4d6f-985f-f0a9fb8b544b"
location                                  = "westeurope"
location_short                            = "weu"
workload                                  = "mlops"
environment                               = "staging"
environment_short                         = "stg"
instance                                  = "01"
enable_private_networking                 = true
managed_network_isolation_mode            = "AllowInternetOutbound"
rg_infra_name                             = "rg-mlops-infra-stg-weu-01"
rg_workload_name                          = "rg-mlops-workload-stg-weu-01"
hub_resource_group_name                   = "rg-hub"
hub_vnet_id                               = "/subscriptions/e19e0ebc-a9ed-4d6f-985f-f0a9fb8b544b/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/hub-vnet"
hub_vnet_name                             = "hub-vnet"
hub_firewall_private_ip                   = "10.0.0.132"
spoke_vnet_name                           = "vnet-mlops-stg-weu-01"
spoke_vnet_cidr                           = "10.1.0.0/22"
spoke_aml_compute_subnet_name             = "snet-mlops-aml-compute"
spoke_aml_compute_subnet_cidr             = "10.1.0.0/24"
spoke_private_endpoints_subnet_name       = "snet-mlops-private-endpoints"
spoke_private_endpoints_subnet_cidr       = "10.1.1.0/26"
spoke_devops_runner_subnet_name           = "snet-mlops-devops-runner"
spoke_devops_runner_subnet_cidr           = "10.1.1.64/27"
shared_log_analytics_workspace_id         = "/subscriptions/e19e0ebc-a9ed-4d6f-985f-f0a9fb8b544b/resourceGroups/rg-hub/providers/Microsoft.OperationalInsights/workspaces/log-hub-weu-01"
shared_application_insights_id            = "/subscriptions/e19e0ebc-a9ed-4d6f-985f-f0a9fb8b544b/resourceGroups/rg-hub/providers/Microsoft.Insights/components/appi-hub-weu-01"
private_dns_zone_id_api_azureml_ms        = "/subscriptions/e19e0ebc-a9ed-4d6f-985f-f0a9fb8b544b/resourceGroups/rg-hub/providers/Microsoft.Network/privateDnsZones/privatelink.api.azureml.ms"
private_dns_zone_id_notebooks_azure_net   = "/subscriptions/e19e0ebc-a9ed-4d6f-985f-f0a9fb8b544b/resourceGroups/rg-hub/providers/Microsoft.Network/privateDnsZones/privatelink.notebooks.azure.net"
private_dns_zone_id_blob_core_windows_net = "/subscriptions/e19e0ebc-a9ed-4d6f-985f-f0a9fb8b544b/resourceGroups/rg-hub/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
private_dns_zone_id_file_core_windows_net = "/subscriptions/e19e0ebc-a9ed-4d6f-985f-f0a9fb8b544b/resourceGroups/rg-hub/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net"
private_dns_zone_id_dfs_core_windows_net  = "/subscriptions/e19e0ebc-a9ed-4d6f-985f-f0a9fb8b544b/resourceGroups/rg-hub/providers/Microsoft.Network/privateDnsZones/privatelink.dfs.core.windows.net"
private_dns_zone_id_vaultcore_azure_net   = "/subscriptions/e19e0ebc-a9ed-4d6f-985f-f0a9fb8b544b/resourceGroups/rg-hub/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
private_dns_zone_id_azurecr_io            = "/subscriptions/e19e0ebc-a9ed-4d6f-985f-f0a9fb8b544b/resourceGroups/rg-hub/providers/Microsoft.Network/privateDnsZones/privatelink.azurecr.io"
endpoint_identity_name                    = "id-mlops-stg-endpoint-weu-01"
runner_identity_name                      = "id-mlops-stg-runner-weu-01"
compute_identity_name                     = "id-mlops-stg-compute-weu-01"
runner_admin_username                     = "azureuser"
runner_admin_password                     = "RunnerVm2026!"
runner_vm_size                            = "Standard_D2s_v3"
aml_compute_name                          = "cpu-cluster-stg"
aml_compute_vm_size                       = "Standard_DS2_v2"
aml_compute_min_instances                 = 0
aml_compute_max_instances                 = 1
github_owner                              = ""
github_repository                         = ""
github_main_branch                        = "main"
github_oidc_role_definition_name          = "Owner"
tag_owner                                 = "tfm"
tag_cost_center                           = "master"

monitoring_action_group_name = "iris-mlops-alerts-group"
monitoring_endpoint_name     = "iris-endpoint-stg-weu-01"
monitoring_alert_emails = [
  "luis-alberto.fernanz-esteban@dxc.com",
  "david.ca.2993@gmail.com",
  "rubendiazblanco02@gmail.com",
  "srgn807@gmail.com",
  "juancarlos.magro@dxc.com"
]

shared_action_group_id = "/subscriptions/e19e0ebc-a9ed-4d6f-985f-f0a9fb8b544b/resourceGroups/rg-hub/providers/Microsoft.Insights/actionGroups/ag-platform-alerts"

monitoring_budget_amount      = 1
monitoring_endpoint_prod_name = "iris-endpoint-prod-weu-01"
