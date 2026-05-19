output "action_group_id" {
  value       = azurerm_monitor_action_group.mlops_alerts.id
  description = "ID del Action Group de alertas"
}

output "dashboard_id" {
  value       = azurerm_portal_dashboard.mlops_monitoring.id
  description = "ID del dashboard de monitorización"
}

output "alert_ids" {
  value = {
    pipeline_failed    = azurerm_monitor_scheduled_query_rules_alert_v2.pipeline_failed.id
    endpoint_errors    = azurerm_monitor_scheduled_query_rules_alert_v2.endpoint_error_rate.id
    endpoint_latency   = azurerm_monitor_scheduled_query_rules_alert_v2.endpoint_high_latency.id
    no_training_24h    = azurerm_monitor_scheduled_query_rules_alert_v2.no_training_24h.id
    compute_no_capacity = azurerm_monitor_scheduled_query_rules_alert_v2.compute_no_capacity.id
  }
  description = "IDs de todas las alertas"
}
