#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_NAME="${CONFIG_NAME:-staging}"
TF_ENV_DIR="${TF_ENV_DIR:-staging}"
CONFIG_FILE="${REPO_ROOT}/config/${CONFIG_NAME}.env"
CONFIG_TEMPLATE="${REPO_ROOT}/config/${CONFIG_NAME}.env.example"
DEFAULT_TEMPLATE="${REPO_ROOT}/config/staging.env.example"
TFVARS_FILE="${REPO_ROOT}/infrastructure/envs/${TF_ENV_DIR}/terraform.tfvars"
TFVARS_SNAPSHOT_FILE="${REPO_ROOT}/infrastructure/envs/${TF_ENV_DIR}/terraform.${CONFIG_NAME}.tfvars"
BACKEND_FILE="${REPO_ROOT}/infrastructure/backend/backend-${CONFIG_NAME}.hcl"
CONFIG_WAS_INITIALIZED=false

ensure_config_file() {
  if [[ -f "$CONFIG_FILE" ]]; then
    return
  fi

  if [[ -f "$CONFIG_TEMPLATE" ]]; then
    cp "$CONFIG_TEMPLATE" "$CONFIG_FILE"
    CONFIG_WAS_INITIALIZED=true
    echo "Initialized config from template: $CONFIG_FILE"
    return
  fi

  cp "$DEFAULT_TEMPLATE" "$CONFIG_FILE"
  CONFIG_WAS_INITIALIZED=true
  echo "Initialized config from default template: $CONFIG_FILE"
}

load_config() {
  set -a
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
  set +a
}

prompt_value() {
  local var_name="$1"
  local prompt_label="$2"
  local default_value="${3:-}"
  local input=""

  if [[ -n "$default_value" ]]; then
    read -r -p "${prompt_label} [${default_value}]: " input || true
    printf -v "$var_name" '%s' "${input:-$default_value}"
  else
    while [[ -z "${!var_name:-}" ]]; do
      read -r -p "${prompt_label}: " input || true
      printf -v "$var_name" '%s' "$input"
    done
  fi
}

prompt_secret() {
  local var_name="$1"
  local prompt_label="$2"
  local current_value="${!var_name:-}"
  local input=""

  if [[ -n "$current_value" ]]; then
    read -r -s -p "${prompt_label} [preserve current]: " input || true
    echo
    printf -v "$var_name" '%s' "${input:-$current_value}"
  else
    while [[ -z "${!var_name:-}" ]]; do
      read -r -s -p "${prompt_label}: " input || true
      echo
      printf -v "$var_name" '%s' "$input"
    done
  fi
}

prompt_optional_value() {
  local var_name="$1"
  local prompt_label="$2"
  local default_value="${3:-}"
  local current_value="${!var_name:-$default_value}"
  local input=""

  read -r -p "${prompt_label} [${current_value}]: " input || true
  printf -v "$var_name" '%s' "${input:-$current_value}"
}

effective_current_value() {
  local current_value="$1"
  local derived_default="$2"

  if [[ "$CONFIG_WAS_INITIALIZED" == "true" ]]; then
    printf '%s' "$derived_default"
  else
    printf '%s' "$current_value"
  fi
}

default_location_short() {
  case "${1,,}" in
    westeurope) printf '%s' "weu" ;;
    francecentral) printf '%s' "frc" ;;
    northeurope) printf '%s' "neu" ;;
    swedencentral) printf '%s' "swc" ;;
    germanywestcentral) printf '%s' "gwc" ;;
    *) printf '%s' "${1:0:3}" | tr '[:upper:]' '[:lower:]' ;;
  esac
}

write_config() {
  cat > "$CONFIG_FILE" <<EOT
# Single source of truth for mlops-platform ${CONFIG_NAME}.

SUBSCRIPTION_ID=${SUBSCRIPTION_ID}
LOCATION=${LOCATION}
LOCATION_SHORT=${LOCATION_SHORT}
WORKLOAD=${WORKLOAD}
ENVIRONMENT=${ENVIRONMENT}
ENVIRONMENT_SHORT=${ENVIRONMENT_SHORT}
INSTANCE=${INSTANCE}
ENABLE_PRIVATE_NETWORKING=${ENABLE_PRIVATE_NETWORKING}
MANAGED_NETWORK_ISOLATION_MODE=${MANAGED_NETWORK_ISOLATION_MODE}

# Backend
TFSTATE_RESOURCE_GROUP=${TFSTATE_RESOURCE_GROUP}
TFSTATE_STORAGE_ACCOUNT=${TFSTATE_STORAGE_ACCOUNT}
TFSTATE_CONTAINER=${TFSTATE_CONTAINER}
TFSTATE_KEY=${TFSTATE_KEY}

# Resource groups
RG_INFRA_NAME=${RG_INFRA_NAME}
RG_WORKLOAD_NAME=${RG_WORKLOAD_NAME}

# Hub objects imported from hub-core-repo
HUB_RESOURCE_GROUP_NAME=${HUB_RESOURCE_GROUP_NAME}
HUB_VNET_ID=${HUB_VNET_ID}
HUB_VNET_NAME=${HUB_VNET_NAME}
HUB_FIREWALL_PRIVATE_IP=${HUB_FIREWALL_PRIVATE_IP}

# Spoke infrastructure created by mlops-platform-repo
SPOKE_VNET_NAME=${SPOKE_VNET_NAME}
SPOKE_VNET_CIDR=${SPOKE_VNET_CIDR}
SPOKE_AML_COMPUTE_SUBNET_NAME=${SPOKE_AML_COMPUTE_SUBNET_NAME}
SPOKE_AML_COMPUTE_SUBNET_CIDR=${SPOKE_AML_COMPUTE_SUBNET_CIDR}
SPOKE_PRIVATE_ENDPOINTS_SUBNET_NAME=${SPOKE_PRIVATE_ENDPOINTS_SUBNET_NAME}
SPOKE_PRIVATE_ENDPOINTS_SUBNET_CIDR=${SPOKE_PRIVATE_ENDPOINTS_SUBNET_CIDR}
SPOKE_DEVOPS_RUNNER_SUBNET_NAME=${SPOKE_DEVOPS_RUNNER_SUBNET_NAME}
SPOKE_DEVOPS_RUNNER_SUBNET_CIDR=${SPOKE_DEVOPS_RUNNER_SUBNET_CIDR}

# Shared observability from hub-core-repo
SHARED_LOG_ANALYTICS_WORKSPACE_ID=${SHARED_LOG_ANALYTICS_WORKSPACE_ID}
SHARED_APPLICATION_INSIGHTS_ID=${SHARED_APPLICATION_INSIGHTS_ID}

# Existing private DNS zones from hub-core-repo
PRIVATE_DNS_ZONE_ID_API_AZUREML_MS=${PRIVATE_DNS_ZONE_ID_API_AZUREML_MS}
PRIVATE_DNS_ZONE_ID_NOTEBOOKS_AZURE_NET=${PRIVATE_DNS_ZONE_ID_NOTEBOOKS_AZURE_NET}
PRIVATE_DNS_ZONE_ID_BLOB_CORE_WINDOWS_NET=${PRIVATE_DNS_ZONE_ID_BLOB_CORE_WINDOWS_NET}
PRIVATE_DNS_ZONE_ID_FILE_CORE_WINDOWS_NET=${PRIVATE_DNS_ZONE_ID_FILE_CORE_WINDOWS_NET}
PRIVATE_DNS_ZONE_ID_DFS_CORE_WINDOWS_NET=${PRIVATE_DNS_ZONE_ID_DFS_CORE_WINDOWS_NET}
PRIVATE_DNS_ZONE_ID_VAULTCORE_AZURE_NET=${PRIVATE_DNS_ZONE_ID_VAULTCORE_AZURE_NET}
PRIVATE_DNS_ZONE_ID_AZURECR_IO=${PRIVATE_DNS_ZONE_ID_AZURECR_IO}

# Identities
ENDPOINT_IDENTITY_NAME=${ENDPOINT_IDENTITY_NAME}
RUNNER_IDENTITY_NAME=${RUNNER_IDENTITY_NAME}
COMPUTE_IDENTITY_NAME=${COMPUTE_IDENTITY_NAME}

# Runner
RUNNER_ADMIN_USERNAME=${RUNNER_ADMIN_USERNAME}
RUNNER_ADMIN_PASSWORD=${RUNNER_ADMIN_PASSWORD}
RUNNER_VM_SIZE=${RUNNER_VM_SIZE}

# AML compute
AML_COMPUTE_NAME=${AML_COMPUTE_NAME}
AML_COMPUTE_VM_SIZE=${AML_COMPUTE_VM_SIZE}
AML_COMPUTE_MIN_INSTANCES=${AML_COMPUTE_MIN_INSTANCES}
AML_COMPUTE_MAX_INSTANCES=${AML_COMPUTE_MAX_INSTANCES}

# GitHub OIDC
GITHUB_OWNER=${GITHUB_OWNER}
GITHUB_REPOSITORY=${GITHUB_REPOSITORY}
GITHUB_MAIN_BRANCH=${GITHUB_MAIN_BRANCH}
GITHUB_OIDC_ROLE_DEFINITION_NAME=${GITHUB_OIDC_ROLE_DEFINITION_NAME}

# Governance
TAG_OWNER=${TAG_OWNER}
TAG_COST_CENTER=${TAG_COST_CENTER}
EOT
}

ensure_config_file
load_config

prompt_value "SUBSCRIPTION_ID" "Azure subscription ID" "${SUBSCRIPTION_ID:-}"
prompt_value "LOCATION" "Azure location" "${LOCATION:-francecentral}"
prompt_value "LOCATION_SHORT" "Azure location short code" "${LOCATION_SHORT:-$(default_location_short "${LOCATION:-francecentral}")}"
prompt_value "WORKLOAD" "Workload name" "${WORKLOAD:-mlops}"
prompt_value "ENVIRONMENT" "Environment" "${ENVIRONMENT:-staging}"
prompt_value "ENVIRONMENT_SHORT" "Environment short code" "${ENVIRONMENT_SHORT:-stg}"
prompt_value "INSTANCE" "Instance" "${INSTANCE:-01}"
prompt_value "ENABLE_PRIVATE_NETWORKING" "Enable private networking (true/false)" "${ENABLE_PRIVATE_NETWORKING:-false}"
prompt_value "MANAGED_NETWORK_ISOLATION_MODE" "Workspace managed network isolation mode" "${MANAGED_NETWORK_ISOLATION_MODE:-AllowInternetOutbound}"

derived_tfstate_resource_group="rg-tfstate-platform-${ENVIRONMENT_SHORT:-stg}-${LOCATION_SHORT:-frc}-${INSTANCE:-01}"
derived_tfstate_storage_account="sttfplatform${ENVIRONMENT_SHORT:-stg}${LOCATION_SHORT:-frc}${INSTANCE:-01}"
derived_tfstate_key="mlops-platform-${CONFIG_NAME}.tfstate"
derived_rg_infra_name="rg-${WORKLOAD:-mlops}-infra-${ENVIRONMENT_SHORT:-stg}-${LOCATION_SHORT:-frc}-${INSTANCE:-01}"
derived_rg_workload_name="rg-${WORKLOAD:-mlops}-workload-${ENVIRONMENT_SHORT:-stg}-${LOCATION_SHORT:-frc}-${INSTANCE:-01}"
derived_spoke_vnet_name="vnet-${WORKLOAD:-mlops}-${ENVIRONMENT_SHORT:-stg}-${LOCATION_SHORT:-frc}-${INSTANCE:-01}"
derived_aml_compute_subnet_name="snet-${WORKLOAD:-mlops}-aml-compute"
derived_private_endpoints_subnet_name="snet-${WORKLOAD:-mlops}-private-endpoints"
derived_devops_runner_subnet_name="snet-${WORKLOAD:-mlops}-devops-runner"
derived_endpoint_identity_name="id-${WORKLOAD:-mlops}-${ENVIRONMENT_SHORT:-stg}-endpoint-${LOCATION_SHORT:-frc}-${INSTANCE:-01}"
derived_runner_identity_name="id-${WORKLOAD:-mlops}-${ENVIRONMENT_SHORT:-stg}-runner-${LOCATION_SHORT:-frc}-${INSTANCE:-01}"
derived_compute_identity_name="id-${WORKLOAD:-mlops}-${ENVIRONMENT_SHORT:-stg}-compute-${LOCATION_SHORT:-frc}-${INSTANCE:-01}"
derived_aml_compute_name="cpu-cluster-${ENVIRONMENT_SHORT:-stg}"

prompt_value "TFSTATE_RESOURCE_GROUP" "Terraform state resource group" "$derived_tfstate_resource_group"
prompt_value "TFSTATE_STORAGE_ACCOUNT" "Terraform state storage account" "$derived_tfstate_storage_account"
prompt_value "TFSTATE_CONTAINER" "Terraform state container" "${TFSTATE_CONTAINER:-tfstate}"
prompt_value "TFSTATE_KEY" "Terraform state key" "$derived_tfstate_key"

prompt_value "RG_INFRA_NAME" "Infra resource group" "$derived_rg_infra_name"
prompt_value "RG_WORKLOAD_NAME" "Workload resource group" "$derived_rg_workload_name"

prompt_value "HUB_RESOURCE_GROUP_NAME" "Hub resource group name" "${HUB_RESOURCE_GROUP_NAME:-}"
prompt_value "HUB_VNET_ID" "Hub VNet ID" "${HUB_VNET_ID:-}"
prompt_value "HUB_VNET_NAME" "Hub VNet name" "${HUB_VNET_NAME:-}"
prompt_value "HUB_FIREWALL_PRIVATE_IP" "Hub firewall private IP" "${HUB_FIREWALL_PRIVATE_IP:-}"
prompt_value "SPOKE_VNET_NAME" "Spoke VNet name" "$derived_spoke_vnet_name"
prompt_value "SPOKE_VNET_CIDR" "Spoke VNet CIDR" "${SPOKE_VNET_CIDR:-10.1.0.0/22}"
prompt_value "SPOKE_AML_COMPUTE_SUBNET_NAME" "AML compute subnet name" "$derived_aml_compute_subnet_name"
prompt_value "SPOKE_AML_COMPUTE_SUBNET_CIDR" "AML compute subnet CIDR" "${SPOKE_AML_COMPUTE_SUBNET_CIDR:-10.1.0.0/24}"
prompt_value "SPOKE_PRIVATE_ENDPOINTS_SUBNET_NAME" "Private endpoints subnet name" "$derived_private_endpoints_subnet_name"
prompt_value "SPOKE_PRIVATE_ENDPOINTS_SUBNET_CIDR" "Private endpoints subnet CIDR" "${SPOKE_PRIVATE_ENDPOINTS_SUBNET_CIDR:-10.1.1.0/26}"
prompt_value "SPOKE_DEVOPS_RUNNER_SUBNET_NAME" "DevOps runner subnet name" "$derived_devops_runner_subnet_name"
prompt_value "SPOKE_DEVOPS_RUNNER_SUBNET_CIDR" "DevOps runner subnet CIDR" "${SPOKE_DEVOPS_RUNNER_SUBNET_CIDR:-10.1.1.64/27}"
prompt_value "SHARED_LOG_ANALYTICS_WORKSPACE_ID" "Shared Log Analytics Workspace ID" "${SHARED_LOG_ANALYTICS_WORKSPACE_ID:-}"
prompt_value "SHARED_APPLICATION_INSIGHTS_ID" "Shared Application Insights ID" "${SHARED_APPLICATION_INSIGHTS_ID:-}"

prompt_value "PRIVATE_DNS_ZONE_ID_API_AZUREML_MS" "Private DNS zone ID api.azureml.ms" "${PRIVATE_DNS_ZONE_ID_API_AZUREML_MS:-}"
prompt_value "PRIVATE_DNS_ZONE_ID_NOTEBOOKS_AZURE_NET" "Private DNS zone ID notebooks.azure.net" "${PRIVATE_DNS_ZONE_ID_NOTEBOOKS_AZURE_NET:-}"
prompt_value "PRIVATE_DNS_ZONE_ID_BLOB_CORE_WINDOWS_NET" "Private DNS zone ID blob.core.windows.net" "${PRIVATE_DNS_ZONE_ID_BLOB_CORE_WINDOWS_NET:-}"
prompt_value "PRIVATE_DNS_ZONE_ID_FILE_CORE_WINDOWS_NET" "Private DNS zone ID file.core.windows.net" "${PRIVATE_DNS_ZONE_ID_FILE_CORE_WINDOWS_NET:-}"
prompt_value "PRIVATE_DNS_ZONE_ID_DFS_CORE_WINDOWS_NET" "Private DNS zone ID dfs.core.windows.net" "${PRIVATE_DNS_ZONE_ID_DFS_CORE_WINDOWS_NET:-}"
prompt_value "PRIVATE_DNS_ZONE_ID_VAULTCORE_AZURE_NET" "Private DNS zone ID vaultcore.azure.net" "${PRIVATE_DNS_ZONE_ID_VAULTCORE_AZURE_NET:-}"
prompt_value "PRIVATE_DNS_ZONE_ID_AZURECR_IO" "Private DNS zone ID azurecr.io" "${PRIVATE_DNS_ZONE_ID_AZURECR_IO:-}"

prompt_value "ENDPOINT_IDENTITY_NAME" "Managed identity name for endpoint" "$derived_endpoint_identity_name"
prompt_value "RUNNER_IDENTITY_NAME" "Managed identity name for runner" "$derived_runner_identity_name"
prompt_value "COMPUTE_IDENTITY_NAME" "Managed identity name for AML compute" "$derived_compute_identity_name"

prompt_value "RUNNER_ADMIN_USERNAME" "Runner admin username" "${RUNNER_ADMIN_USERNAME:-azureuser}"
prompt_secret "RUNNER_ADMIN_PASSWORD" "Runner admin password"
prompt_value "RUNNER_VM_SIZE" "Runner VM size" "${RUNNER_VM_SIZE:-Standard_D2s_v3}"

prompt_value "AML_COMPUTE_NAME" "AML compute cluster name" "$derived_aml_compute_name"
prompt_value "AML_COMPUTE_VM_SIZE" "AML compute VM size" "${AML_COMPUTE_VM_SIZE:-Standard_DS2_v2}"
prompt_value "AML_COMPUTE_MIN_INSTANCES" "AML compute min instances" "${AML_COMPUTE_MIN_INSTANCES:-0}"
prompt_value "AML_COMPUTE_MAX_INSTANCES" "AML compute max instances" "${AML_COMPUTE_MAX_INSTANCES:-1}"

prompt_optional_value "GITHUB_OWNER" "GitHub owner or organization" "${GITHUB_OWNER:-}"
prompt_optional_value "GITHUB_REPOSITORY" "GitHub repository name" "${GITHUB_REPOSITORY:-}"
prompt_value "GITHUB_MAIN_BRANCH" "GitHub main branch" "${GITHUB_MAIN_BRANCH:-main}"
prompt_value "GITHUB_OIDC_ROLE_DEFINITION_NAME" "GitHub OIDC Azure role definition name" "${GITHUB_OIDC_ROLE_DEFINITION_NAME:-Owner}"

prompt_value "TAG_OWNER" "Owner tag" "${TAG_OWNER:-tfm}"
prompt_value "TAG_COST_CENTER" "Cost center tag" "${TAG_COST_CENTER:-master}"

write_config
load_config

cat > "$TFVARS_FILE" <<EOT
subscription_id                         = "${SUBSCRIPTION_ID}"
location                                = "${LOCATION}"
location_short                          = "${LOCATION_SHORT}"
workload                                = "${WORKLOAD}"
environment                             = "${ENVIRONMENT}"
environment_short                       = "${ENVIRONMENT_SHORT}"
instance                                = "${INSTANCE}"
enable_private_networking               = ${ENABLE_PRIVATE_NETWORKING}
managed_network_isolation_mode          = "${MANAGED_NETWORK_ISOLATION_MODE}"
rg_infra_name                           = "${RG_INFRA_NAME}"
rg_workload_name                        = "${RG_WORKLOAD_NAME}"
hub_resource_group_name                 = "${HUB_RESOURCE_GROUP_NAME}"
hub_vnet_id                             = "${HUB_VNET_ID}"
hub_vnet_name                           = "${HUB_VNET_NAME}"
hub_firewall_private_ip                 = "${HUB_FIREWALL_PRIVATE_IP}"
spoke_vnet_name                         = "${SPOKE_VNET_NAME}"
spoke_vnet_cidr                         = "${SPOKE_VNET_CIDR}"
spoke_aml_compute_subnet_name           = "${SPOKE_AML_COMPUTE_SUBNET_NAME}"
spoke_aml_compute_subnet_cidr           = "${SPOKE_AML_COMPUTE_SUBNET_CIDR}"
spoke_private_endpoints_subnet_name     = "${SPOKE_PRIVATE_ENDPOINTS_SUBNET_NAME}"
spoke_private_endpoints_subnet_cidr     = "${SPOKE_PRIVATE_ENDPOINTS_SUBNET_CIDR}"
spoke_devops_runner_subnet_name         = "${SPOKE_DEVOPS_RUNNER_SUBNET_NAME}"
spoke_devops_runner_subnet_cidr         = "${SPOKE_DEVOPS_RUNNER_SUBNET_CIDR}"
shared_log_analytics_workspace_id       = "${SHARED_LOG_ANALYTICS_WORKSPACE_ID}"
shared_application_insights_id          = "${SHARED_APPLICATION_INSIGHTS_ID}"
private_dns_zone_id_api_azureml_ms      = "${PRIVATE_DNS_ZONE_ID_API_AZUREML_MS}"
private_dns_zone_id_notebooks_azure_net = "${PRIVATE_DNS_ZONE_ID_NOTEBOOKS_AZURE_NET}"
private_dns_zone_id_blob_core_windows_net = "${PRIVATE_DNS_ZONE_ID_BLOB_CORE_WINDOWS_NET}"
private_dns_zone_id_file_core_windows_net = "${PRIVATE_DNS_ZONE_ID_FILE_CORE_WINDOWS_NET}"
private_dns_zone_id_dfs_core_windows_net  = "${PRIVATE_DNS_ZONE_ID_DFS_CORE_WINDOWS_NET}"
private_dns_zone_id_vaultcore_azure_net   = "${PRIVATE_DNS_ZONE_ID_VAULTCORE_AZURE_NET}"
private_dns_zone_id_azurecr_io            = "${PRIVATE_DNS_ZONE_ID_AZURECR_IO}"
endpoint_identity_name                  = "${ENDPOINT_IDENTITY_NAME}"
runner_identity_name                    = "${RUNNER_IDENTITY_NAME}"
compute_identity_name                   = "${COMPUTE_IDENTITY_NAME}"
runner_admin_username                   = "${RUNNER_ADMIN_USERNAME}"
runner_admin_password                   = "${RUNNER_ADMIN_PASSWORD}"
runner_vm_size                          = "${RUNNER_VM_SIZE}"
aml_compute_name                        = "${AML_COMPUTE_NAME}"
aml_compute_vm_size                     = "${AML_COMPUTE_VM_SIZE}"
aml_compute_min_instances               = ${AML_COMPUTE_MIN_INSTANCES}
aml_compute_max_instances               = ${AML_COMPUTE_MAX_INSTANCES}
github_owner                            = "${GITHUB_OWNER}"
github_repository                       = "${GITHUB_REPOSITORY}"
github_main_branch                      = "${GITHUB_MAIN_BRANCH}"
github_oidc_role_definition_name        = "${GITHUB_OIDC_ROLE_DEFINITION_NAME}"
tag_owner                               = "${TAG_OWNER}"
tag_cost_center                         = "${TAG_COST_CENTER}"
EOT

cp "$TFVARS_FILE" "$TFVARS_SNAPSHOT_FILE"

cat > "$BACKEND_FILE" <<EOT
resource_group_name  = "${TFSTATE_RESOURCE_GROUP}"
storage_account_name = "${TFSTATE_STORAGE_ACCOUNT}"
container_name       = "${TFSTATE_CONTAINER}"
key                  = "${TFSTATE_KEY}"
EOT

echo "Generated: $TFVARS_FILE"
echo "Generated: $TFVARS_SNAPSHOT_FILE"
echo "Generated: $BACKEND_FILE"
echo "Saved config: $CONFIG_FILE"
