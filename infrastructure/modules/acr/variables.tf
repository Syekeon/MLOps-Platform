variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "acr_name" { type = string }
variable "enable_private_networking" { type = bool }
variable "tags" { type = map(string) }

variable "soft_delete_retention_days" {
  type        = number
  description = "Días de retención para soft delete de imágenes en ACR"
  default     = 7
}
