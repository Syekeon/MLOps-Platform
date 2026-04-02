#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKLOAD_CONFIG_NAME="${WORKLOAD_CONFIG_NAME:-${CONFIG_NAME:-staging}}"
HUB_CONFIG_NAME="${HUB_CONFIG_NAME:-shared}"
WORKLOAD_CONFIG_FILE="${REPO_ROOT}/config/${WORKLOAD_CONFIG_NAME}.env"
HUB_REPO_ROOT="${HUB_REPO_ROOT:-${REPO_ROOT}/../hub-core-repo}"
HUB_ENV_DIR="${HUB_ENV_DIR:-shared}"
HUB_TERRAFORM_DIR="${HUB_REPO_ROOT}/infrastructure/envs/${HUB_ENV_DIR}"

ensure_workload_config() {
  if [[ -f "$WORKLOAD_CONFIG_FILE" ]]; then
    return
  fi

  cat > "$WORKLOAD_CONFIG_FILE" <<'EOT'
# Imported values from hub-core-repo.
# Run render-workload-config.sh afterwards to complete the workload config.
EOT
  echo "Initialized workload config for imported values: $WORKLOAD_CONFIG_FILE"
}

require_hub_state() {
  if [[ ! -d "$HUB_TERRAFORM_DIR" ]]; then
    echo "Hub Terraform directory not found: $HUB_TERRAFORM_DIR" >&2
    exit 1
  fi
}

terraform_output_raw() {
  local output_name="$1"
  terraform -chdir="$HUB_TERRAFORM_DIR" output -raw "$output_name"
}

terraform_output_zone_id() {
  local zone_name="$1"
  local json

  json="$(terraform -chdir="$HUB_TERRAFORM_DIR" output -json private_dns_zone_ids)"
  python3 -c 'import json,sys; print(json.loads(sys.stdin.read())[sys.argv[1]])' "$zone_name" <<<"$json"
}

upsert_env_var() {
  local key="$1"
  local value="$2"
  local escaped_value

  escaped_value="$(printf '%s' "$value" | sed 's/[\/&]/\\&/g')"

  if grep -q "^${key}=" "$WORKLOAD_CONFIG_FILE"; then
    sed -i "s/^${key}=.*/${key}=${escaped_value}/" "$WORKLOAD_CONFIG_FILE"
  else
    printf '%s=%s\n' "$key" "$value" >> "$WORKLOAD_CONFIG_FILE"
  fi
}

ensure_workload_config
require_hub_state

upsert_env_var "HUB_RESOURCE_GROUP_NAME" "$(terraform_output_raw "hub_resource_group_name")"
upsert_env_var "HUB_VNET_ID" "$(terraform_output_raw "hub_vnet_id")"
upsert_env_var "HUB_VNET_NAME" "$(terraform_output_raw "hub_vnet_name")"
upsert_env_var "HUB_FIREWALL_PRIVATE_IP" "$(terraform_output_raw "hub_firewall_private_ip")"
upsert_env_var "SHARED_LOG_ANALYTICS_WORKSPACE_ID" "$(terraform_output_raw "log_analytics_workspace_id")"
upsert_env_var "SHARED_APPLICATION_INSIGHTS_ID" "$(terraform_output_raw "application_insights_id")"
upsert_env_var "PRIVATE_DNS_ZONE_ID_API_AZUREML_MS" "$(terraform_output_zone_id "privatelink.api.azureml.ms")"
upsert_env_var "PRIVATE_DNS_ZONE_ID_NOTEBOOKS_AZURE_NET" "$(terraform_output_zone_id "privatelink.notebooks.azure.net")"
upsert_env_var "PRIVATE_DNS_ZONE_ID_BLOB_CORE_WINDOWS_NET" "$(terraform_output_zone_id "privatelink.blob.core.windows.net")"
upsert_env_var "PRIVATE_DNS_ZONE_ID_FILE_CORE_WINDOWS_NET" "$(terraform_output_zone_id "privatelink.file.core.windows.net")"
upsert_env_var "PRIVATE_DNS_ZONE_ID_DFS_CORE_WINDOWS_NET" "$(terraform_output_zone_id "privatelink.dfs.core.windows.net")"
upsert_env_var "PRIVATE_DNS_ZONE_ID_VAULTCORE_AZURE_NET" "$(terraform_output_zone_id "privatelink.vaultcore.azure.net")"
upsert_env_var "PRIVATE_DNS_ZONE_ID_AZURECR_IO" "$(terraform_output_zone_id "privatelink.azurecr.io")"

echo "Updated workload config from hub outputs: $WORKLOAD_CONFIG_FILE"
echo "Hub source: $HUB_TERRAFORM_DIR"
