resource "azurerm_resource_group_template_deployment" "this" {
  name                = "dep-${var.compute_name}"
  resource_group_name = var.resource_group_name
  deployment_mode     = "Incremental"

  template_content = jsonencode({
    "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
    contentVersion = "1.0.0.0"
    parameters     = merge(
      {
        workspaceId = {
          type = "String"
        }
        computeName = {
          type = "String"
        }
        location = {
          type = "String"
        }
        userAssignedIdentityId = {
          type = "String"
        }
        vmSize = {
          type = "String"
        }
        minInstances = {
          type = "Int"
        }
        maxInstances = {
          type = "Int"
        }
        enableNodePublicIp = {
          type = "Bool"
        }
        remoteLoginPortPublicAccess = {
          type = "String"
        }
        tags = {
          type = "Object"
        }
      },
      var.subnet_id == null ? {} : {
        subnetId = {
          type = "String"
        }
        adminUsername = {
          type = "String"
        }
        adminPassword = {
          type = "SecureString"
        }
      }
    )
    resources        = [
      {
        type       = "Microsoft.MachineLearningServices/workspaces/computes"
        apiVersion = "2022-10-01"
        name       = "[format('{0}/{1}', last(split(parameters('workspaceId'), '/')), parameters('computeName'))]"
        location   = "[parameters('location')]"
        identity   = {
          type                   = "UserAssigned"
          userAssignedIdentities = {
            "[parameters('userAssignedIdentityId')]" = {}
          }
        }
        tags       = "[parameters('tags')]"
        properties = {
          computeLocation  = "[parameters('location')]"
          computeType      = "AmlCompute"
          disableLocalAuth = false
          properties       = merge(
            {
              enableNodePublicIp          = "[parameters('enableNodePublicIp')]"
              isolatedNetwork             = false
              osType                      = "Linux"
              remoteLoginPortPublicAccess = "[parameters('remoteLoginPortPublicAccess')]"
              scaleSettings               = {
                minNodeCount                = "[parameters('minInstances')]"
                maxNodeCount                = "[parameters('maxInstances')]"
                nodeIdleTimeBeforeScaleDown = "PT15M"
              }
              vmPriority                  = "Dedicated"
              vmSize                      = "[parameters('vmSize')]"
            },
            var.subnet_id == null ? {} : {
              userAccountCredentials = {
                adminUserName     = "[parameters('adminUsername')]"
                adminUserPassword = "[parameters('adminPassword')]"
              }
              subnet = {
                id = "[parameters('subnetId')]"
              }
            }
          )
        }
      }
    ]
    outputs          = {
      id = {
        type  = "String"
        value = "[resourceId('Microsoft.MachineLearningServices/workspaces/computes', last(split(parameters('workspaceId'), '/')), parameters('computeName'))]"
      }
      name = {
        type  = "String"
        value = "[parameters('computeName')]"
      }
      principalId = {
        type  = "String"
        value = "[reference(resourceId('Microsoft.MachineLearningServices/workspaces/computes', last(split(parameters('workspaceId'), '/')), parameters('computeName')), '2022-10-01', 'Full').identity.userAssignedIdentities[parameters('userAssignedIdentityId')].principalId]"
      }
    }
  })

  parameters_content = jsonencode(merge(
    {
      workspaceId = {
        value = var.workspace_id
      }
      computeName = {
        value = var.compute_name
      }
      location = {
        value = var.location
      }
      userAssignedIdentityId = {
        value = var.user_assigned_identity_id
      }
      vmSize = {
        value = var.vm_size
      }
      minInstances = {
        value = var.min_instances
      }
      maxInstances = {
        value = var.max_instances
      }
      enableNodePublicIp = {
        value = var.enable_node_public_ip
      }
      remoteLoginPortPublicAccess = {
        value = var.ssh_public_access_enabled ? "Enabled" : "Disabled"
      }
      tags = {
        value = var.tags
      }
    },
    var.subnet_id == null ? {} : {
      adminUsername = {
        value = var.admin_username
      }
      adminPassword = {
        value = var.admin_password
      }
      subnetId = {
        value = var.subnet_id
      }
    }
  ))

}
