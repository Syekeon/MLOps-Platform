variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "route_table_name" {
  type = string
}

variable "next_hop_ip_address" {
  type = string
}

variable "aml_compute_subnet_id" {
  type = string
}

variable "devops_runner_subnet_id" {
  type = string
}

variable "tags" {
  type = map(string)
}
