locals {
  assignments = {
    workspace_acr_push = {
      scope                = var.acr_id
      role_definition_name = "AcrPush"
      principal_id         = var.aml_workspace_principal_id
    }
    workspace_key_vault_secrets_officer = {
      scope                = var.key_vault_id
      role_definition_name = "Key Vault Secrets Officer"
      principal_id         = var.aml_workspace_principal_id
    }
    endpoint_storage_blob_reader = {
      scope                = var.storage_account_id
      role_definition_name = "Storage Blob Data Reader"
      principal_id         = var.endpoint_identity_principal_id
    }
    endpoint_acr_pull = {
      scope                = var.acr_id
      role_definition_name = "AcrPull"
      principal_id         = var.endpoint_identity_principal_id
    }
    endpoint_key_vault_secrets_user = {
      scope                = var.key_vault_id
      role_definition_name = "Key Vault Secrets User"
      principal_id         = var.endpoint_identity_principal_id
    }
    runner_workload_rg_contributor = {
      scope                = var.resource_group_id
      role_definition_name = "Contributor"
      principal_id         = var.runner_identity_principal_id
    }
    runner_storage_blob_contributor = {
      scope                = var.storage_account_id
      role_definition_name = "Storage Blob Data Contributor"
      principal_id         = var.runner_identity_principal_id
    }
    runner_acr_push = {
      scope                = var.acr_id
      role_definition_name = "AcrPush"
      principal_id         = var.runner_identity_principal_id
    }
    runner_key_vault_secrets_officer = {
      scope                = var.key_vault_id
      role_definition_name = "Key Vault Secrets Officer"
      principal_id         = var.runner_identity_principal_id
    }
    compute_storage_blob_contributor = {
      scope                = var.storage_account_id
      role_definition_name = "Storage Blob Data Contributor"
      principal_id         = var.compute_identity_principal_id
    }
    compute_key_vault_secrets_user = {
      scope                = var.key_vault_id
      role_definition_name = "Key Vault Secrets User"
      principal_id         = var.compute_identity_principal_id
    }
  }
}

resource "azurerm_role_assignment" "this" {
  for_each             = local.assignments
  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}
