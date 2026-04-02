data "azurerm_client_config" "current" {}

locals {
  branch_subject = "repo:${var.github_owner}/${var.github_repository}:ref:refs/heads/${var.github_main_branch}"
}

resource "azuread_application" "this" {
  display_name     = var.application_display_name
  sign_in_audience = "AzureADMyOrg"
}

resource "azuread_service_principal" "this" {
  client_id                    = azuread_application.this.client_id
  app_role_assignment_required = false
}

resource "azuread_application_federated_identity_credential" "branch" {
  application_id = azuread_application.this.id
  display_name   = "github-${var.github_owner}-${var.github_repository}-${var.github_main_branch}"
  description    = "OIDC federated credential for GitHub Actions branch ${var.github_main_branch}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = local.branch_subject
}

resource "azurerm_role_assignment" "scope" {
  count                = var.role_definition_name == "" ? 0 : 1
  scope                = var.scope
  role_definition_name = var.role_definition_name
  principal_id         = azuread_service_principal.this.object_id
}
