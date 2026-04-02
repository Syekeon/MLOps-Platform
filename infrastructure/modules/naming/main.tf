locals {
  region_short = lookup({
    westeurope           = "weu"
    francecentral        = "frc"
    northeurope          = "neu"
    swedencentral        = "swc"
    germanywestcentral   = "gwc"
  }, var.location, substr(var.location, 0, 3))

  log_analytics_name      = "log-${var.workload}-${var.environment_short}-${local.region_short}-${var.instance}"
  application_insights_name = "appi-${var.workload}-${var.environment_short}-${local.region_short}-${var.instance}"
  key_vault_name          = "kv-${var.workload}-${var.environment_short}-${local.region_short}-${var.instance}"
  aml_workspace_name      = "mlw-${var.workload}-${var.environment_short}-${local.region_short}-${var.instance}"
  runner_vm_name          = "vm-${var.workload}-${var.environment_short}-runner-${local.region_short}-${var.instance}"
  runner_nic_name         = "nic-${var.workload}-${var.environment_short}-runner-${local.region_short}-${var.instance}"
  compute_identity_name   = "id-${var.workload}-${var.environment_short}-compute-${local.region_short}-${var.instance}"

  storage_account_name = substr(replace("st${var.workload}${var.environment_short}${local.region_short}${var.instance}", "-", ""), 0, 24)
  acr_name             = substr(replace("acr${var.workload}${var.environment_short}${local.region_short}${var.instance}", "-", ""), 0, 50)
}
