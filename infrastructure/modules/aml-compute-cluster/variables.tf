variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "workspace_id" { type = string }
variable "compute_name" { type = string }
variable "subnet_id" {
  type    = string
  default = null
}
variable "user_assigned_identity_id" { type = string }
variable "vm_size" { type = string }
variable "min_instances" { type = number }
variable "max_instances" { type = number }
variable "enable_node_public_ip" { type = bool }
variable "ssh_public_access_enabled" { type = bool }
variable "admin_username" { type = string }
variable "admin_password" {
  type      = string
  sensitive = true
}
variable "tags" { type = map(string) }
