variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "spoke_vnet_name" {
  type = string
}

variable "spoke_vnet_cidr" {
  type = string
}

variable "aml_compute_subnet_name" {
  type = string
}

variable "aml_compute_subnet_cidr" {
  type = string
}

variable "private_endpoints_subnet_name" {
  type = string
}

variable "private_endpoints_subnet_cidr" {
  type = string
}

variable "devops_runner_subnet_name" {
  type = string
}

variable "devops_runner_subnet_cidr" {
  type = string
}

variable "tags" {
  type = map(string)
}
