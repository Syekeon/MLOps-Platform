variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "endpoint_identity_name" { type = string }
variable "runner_identity_name" { type = string }
variable "compute_identity_name" { type = string }
variable "tags" { type = map(string) }
