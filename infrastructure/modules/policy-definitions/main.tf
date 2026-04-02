locals {
  definitions = {
    storage_public_access = {
      name         = "audit-storage-public-access-disabled"
      display_name = "Audit Storage public network access disabled"
      description  = "Audit Storage Accounts with public network access enabled."
      category     = "Network"
      rule = {
        if = {
          allOf = [
            {
              field  = "type"
              equals = "Microsoft.Storage/storageAccounts"
            },
            {
              field     = "Microsoft.Storage/storageAccounts/publicNetworkAccess"
              notEquals = "Disabled"
            }
          ]
        }
        then = {
          effect = "audit"
        }
      }
      parameters = null
    }
    keyvault_public_access = {
      name         = "audit-keyvault-public-access-disabled"
      display_name = "Audit Key Vault public network access disabled"
      description  = "Audit Key Vaults with public network access enabled."
      category     = "Network"
      rule = {
        if = {
          allOf = [
            {
              field  = "type"
              equals = "Microsoft.KeyVault/vaults"
            },
            {
              field     = "Microsoft.KeyVault/vaults/publicNetworkAccess"
              notEquals = "Disabled"
            }
          ]
        }
        then = {
          effect = "audit"
        }
      }
      parameters = null
    }
    acr_public_access = {
      name         = "audit-acr-public-access-disabled"
      display_name = "Audit ACR public network access disabled"
      description  = "Audit Container Registries with public network access enabled."
      category     = "Network"
      rule = {
        if = {
          allOf = [
            {
              field  = "type"
              equals = "Microsoft.ContainerRegistry/registries"
            },
            {
              field     = "Microsoft.ContainerRegistry/registries/publicNetworkAccess"
              notEquals = "Disabled"
            }
          ]
        }
        then = {
          effect = "audit"
        }
      }
      parameters = null
    }
    aml_workspace_public_access = {
      name         = "audit-aml-workspace-public-access-disabled"
      display_name = "Audit AML Workspace public network access disabled"
      description  = "Audit Azure Machine Learning Workspaces with public network access enabled."
      category     = "Network"
      rule = {
        if = {
          allOf = [
            {
              field  = "type"
              equals = "Microsoft.MachineLearningServices/workspaces"
            },
            {
              field     = "Microsoft.MachineLearningServices/workspaces/publicNetworkAccess"
              notEquals = "Disabled"
            }
          ]
        }
        then = {
          effect = "audit"
        }
      }
      parameters = null
    }
    runner_vm_sizes = {
      name         = "audit-allowed-vm-sizes"
      display_name = "Audit allowed VM sizes for workload VMs"
      description  = "Audit workload virtual machines whose size is not in the approved list."
      category     = "Cost Management"
      rule = {
        if = {
          allOf = [
            {
              field  = "type"
              equals = "Microsoft.Compute/virtualMachines"
            },
            {
              field = "Microsoft.Compute/virtualMachines/hardwareProfile.vmSize"
              notIn = "[parameters('allowedSizes')]"
            }
          ]
        }
        then = {
          effect = "audit"
        }
      }
      parameters = {
        allowedSizes = {
          type = "Array"
          metadata = {
            displayName = "Allowed sizes"
          }
        }
      }
    }
    aml_compute_sizes = {
      name         = "audit-allowed-aml-compute-sizes"
      display_name = "Audit allowed AML compute sizes"
      description  = "Audit AML compute clusters whose vmSize is not in the approved list."
      category     = "Cost Management"
      rule = {
        if = {
          allOf = [
            {
              field  = "type"
              equals = "Microsoft.MachineLearningServices/workspaces/computes"
            },
            {
              field = "Microsoft.MachineLearningServices/workspaces/computes/vmSize"
              notIn = "[parameters('allowedSizes')]"
            }
          ]
        }
        then = {
          effect = "audit"
        }
      }
      parameters = {
        allowedSizes = {
          type = "Array"
          metadata = {
            displayName = "Allowed sizes"
          }
        }
      }
    }
    online_deployment_sizes = {
      name         = "audit-allowed-aml-online-deployment-sizes"
      display_name = "Audit allowed AML online deployment sizes"
      description  = "Audit AML managed online deployments whose instanceType is not in the approved list."
      category     = "Cost Management"
      rule = {
        if = {
          allOf = [
            {
              field  = "type"
              equals = "Microsoft.MachineLearningServices/workspaces/onlineEndpoints/deployments"
            },
            {
              field = "Microsoft.MachineLearningServices/workspaces/onlineEndpoints/deployments/instanceType"
              notIn = "[parameters('allowedSizes')]"
            }
          ]
        }
        then = {
          effect = "audit"
        }
      }
      parameters = {
        allowedSizes = {
          type = "Array"
          metadata = {
            displayName = "Allowed sizes"
          }
        }
      }
    }
  }
}

resource "azurerm_policy_definition" "this" {
  for_each     = local.definitions
  name         = each.value.name
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = each.value.display_name
  description  = each.value.description

  metadata = jsonencode({
    category = each.value.category
  })

  parameters  = each.value.parameters == null ? null : jsonencode(each.value.parameters)
  policy_rule = jsonencode(each.value.rule)
}
