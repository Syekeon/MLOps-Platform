variable "application_display_name" { type = string }
variable "github_owner" { type = string }
variable "github_repository" { type = string }
variable "github_main_branch" { type = string }
variable "scope" { type = string }
variable "role_definition_name" {
  type    = string
  default = "Owner"
}
