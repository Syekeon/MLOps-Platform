variable "environment" {
  type        = string
  description = "Nombre del entorno (staging, prod)"
}

variable "location" {
  type        = string
  description = "Región de Azure"
}

variable "workload_resource_group_name" {
  type        = string
  description = "Resource group del workload"
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "ID del Log Analytics Workspace"
}

variable "application_insights_id" {
  type        = string
  description = "ID del Application Insights"
}

variable "aml_workspace_id" {
  type        = string
  description = "ID del AML Workspace"
}

variable "aml_workspace_name" {
  type        = string
  description = "Nombre del AML Workspace"
}

variable "endpoint_name" {
  type        = string
  description = "Nombre del endpoint de inferencia staging"
}

variable "compute_cluster_name" {
  type        = string
  description = "Nombre del compute cluster"
}

variable "alert_emails" {
  type        = list(string)
  description = "Lista de emails que reciben alertas"
}

variable "action_group_name" {
  type        = string
  description = "Nombre del action group"
  default     = "iris-mlops-alerts-group"
}

variable "tags" {
  type        = map(string)
  description = "Tags comunes"
}

variable "shared_action_group_id" {
  type        = string
  description = "ID del Action Group ag-platform-alerts del Hub-Core"
}

variable "runner_vm_name" {
  type        = string
  description = "Nombre de la runner VM"
  default     = "vm-mlops-stg-runner-weu-01"
}

variable "subscription_id" {
  type        = string
  description = "ID de la suscripción de Azure"
}

variable "monthly_budget_amount" {
  type        = number
  description = "Presupuesto mensual en euros"
  default     = 1
}

variable "endpoint_prod_name" {
  type        = string
  description = "Nombre del endpoint de producción"
  default     = "iris-endpoint-prod-weu-01"
}
