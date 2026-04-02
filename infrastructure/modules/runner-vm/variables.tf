variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "vm_name" { type = string }
variable "nic_name" { type = string }
variable "subnet_id" { type = string }
variable "admin_username" { type = string }
variable "admin_password" {
  type      = string
  sensitive = true
}
variable "vm_size" { type = string }
variable "user_assigned_identity_id" { type = string }
variable "tags" { type = map(string) }
