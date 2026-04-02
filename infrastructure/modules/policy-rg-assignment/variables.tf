variable "assignment_name" { type = string }
variable "scope_id" { type = string }
variable "policy_definition_id" { type = string }
variable "display_name" { type = string }
variable "parameters_json" {
  type    = string
  default = null
}
