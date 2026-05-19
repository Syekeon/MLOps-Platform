# ============================================================
# Action Group — destinatarios de las alertas
# ============================================================
resource "azurerm_monitor_action_group" "mlops_alerts" {
  name                = var.action_group_name
  resource_group_name = var.workload_resource_group_name
  short_name          = "mlops"
  tags                = var.tags

  dynamic "email_receiver" {
    for_each = var.alert_emails
    content {
      name                    = "email-${index(var.alert_emails, email_receiver.value)}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }
}

# ============================================================
# Alerta 1 — Pipeline de entrenamiento fallido
# ============================================================
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "pipeline_failed" {
  name                = "alert-mlops-pipeline-failed"
  resource_group_name = var.workload_resource_group_name
  location            = var.location
  tags                = var.tags

  display_name        = "[MLOps][CRÍTICO] Pipeline de entrenamiento fallido"
  description         = "El pipeline de entrenamiento del modelo Iris ha fallado."
  severity            = 0
  enabled             = true
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"

  scopes = [var.log_analytics_workspace_id]

  criteria {
    query = <<-QUERY
      AmlComputeJobEvent
      | where EventType == "JobFailed"
      | where ClusterId contains "${var.compute_cluster_name}"
      | summarize FailedJobs = count() by bin(TimeGenerated, 5m)
      | where FailedJobs > 0
    QUERY

    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.mlops_alerts.id]
  }
}

# ============================================================
# Alerta 2 — Endpoint staging con alta tasa de errores (>5%)
# ============================================================
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "endpoint_error_rate" {
  name                = "alert-mlops-endpoint-error-rate"
  resource_group_name = var.workload_resource_group_name
  location            = var.location
  tags                = var.tags

  display_name        = "[MLOps][CRÍTICO] Endpoint staging no disponible"
  description         = "Más del 5% de las peticiones al endpoint de staging están fallando."
  severity            = 0
  enabled             = true
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"

  scopes = [var.log_analytics_workspace_id]

  criteria {
    query = <<-QUERY
      AmlOnlineEndpointTrafficLog
      | where EndpointName == "${var.endpoint_name}"
      | summarize
          TotalRequests = count(),
          ErrorRequests = countif(ResponseCode >= 500)
        by bin(TimeGenerated, 5m)
      | where TotalRequests > 0
      | extend ErrorRate = (ErrorRequests * 100.0) / TotalRequests
      | where ErrorRate > 5
    QUERY

    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.mlops_alerts.id]
  }
}

# ============================================================
# Alerta 3 — Latencia alta en endpoint staging (>2s)
# ============================================================
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "endpoint_high_latency" {
  name                = "alert-mlops-endpoint-latency"
  resource_group_name = var.workload_resource_group_name
  location            = var.location
  tags                = var.tags

  display_name        = "[MLOps][AVISO] Latencia alta en endpoint staging"
  description         = "El tiempo de respuesta del endpoint supera los 2 segundos."
  severity            = 1
  enabled             = true
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"

  scopes = [var.log_analytics_workspace_id]

  criteria {
    query = <<-QUERY
      AmlOnlineEndpointTrafficLog
      | where EndpointName == "${var.endpoint_name}"
      | summarize AvgLatency = avg(RequestDurationMs) by bin(TimeGenerated, 5m)
      | where AvgLatency > 2000
    QUERY

    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.mlops_alerts.id]
  }
}

# ============================================================
# Alerta 4 — Sin entrenamientos en 24 horas
# ============================================================
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "no_training_24h" {
  name                = "alert-mlops-no-training-24h"
  resource_group_name = var.workload_resource_group_name
  location            = var.location
  tags                = var.tags

  display_name        = "[MLOps][AVISO] Sin entrenamientos en 24 horas"
  description         = "No se ha registrado ningún job de entrenamiento en las últimas 24 horas."
  severity            = 1
  enabled             = true
  evaluation_frequency = "PT1H"
  window_duration      = "PT6H"

  scopes = [var.log_analytics_workspace_id]

  criteria {
    query = <<-QUERY
      AmlComputeJobEvent
      | where EventType == "JobSubmitted"
      | where ClusterId contains "${var.compute_cluster_name}"
      | summarize JobCount = count() by bin(TimeGenerated, 1h)
    QUERY

    time_aggregation_method = "Count"
    threshold               = 1
    operator                = "LessThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 6
      number_of_evaluation_periods             = 6
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.mlops_alerts.id]
  }
}

# ============================================================
# Alerta 5 — Compute cluster sin capacidad >30 min
# ============================================================
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "compute_no_capacity" {
  name                = "alert-mlops-compute-no-capacity"
  resource_group_name = var.workload_resource_group_name
  location            = var.location
  tags                = var.tags

  display_name        = "[MLOps][AVISO] Compute cluster sin capacidad"
  description         = "El cluster cpu-cluster-stg lleva más de 30 minutos sin nodos disponibles con jobs en cola."
  severity            = 1
  enabled             = true
  evaluation_frequency = "PT5M"
  window_duration      = "PT30M"

  scopes = [var.log_analytics_workspace_id]

  criteria {
    query = <<-QUERY
      AmlComputeClusterEvent
      | where ClusterName == "${var.compute_cluster_name}"
      | where EventType == "ResizingTimeout"
      | summarize TimeoutCount = count() by bin(TimeGenerated, 5m)
      | where TimeoutCount > 0
    QUERY

    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.mlops_alerts.id]
  }
}

# ============================================================
# Dashboard — MLOps Platform - Iris Classifier Monitoring
# ============================================================
resource "azurerm_portal_dashboard" "mlops_monitoring" {
  name                = "dashboard-mlops-${var.environment}-weu-01"
  resource_group_name = var.workload_resource_group_name
  location            = var.location
  tags                = merge(var.tags, { hidden-title = "MLOps Platform - Iris Classifier Monitoring" })

  dashboard_properties = jsonencode({
    lenses = {
      "0" = {
        order = 0
        parts = {
          # Widget 1 — Peticiones al endpoint
          "0" = {
            position = { x = 0, y = 0, colSpan = 6, rowSpan = 4 }
            metadata = {
              type = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
              inputs = [
                { name = "resourceTypeMode", isOptional = true, value = "workspace" },
                { name = "ComponentId", isOptional = true, value = { SubscriptionId = "", ResourceGroup = var.workload_resource_group_name, Name = "", ResourceId = var.log_analytics_workspace_id } },
                {
                  name = "Query"
                  value = "AmlOnlineEndpointTrafficLog\n| where EndpointName == \"${var.endpoint_name}\"\n| summarize Peticiones = count() by bin(TimeGenerated, 1h)\n| render timechart"
                },
                { name = "TimeRange", value = "P1D" },
                { name = "Version", value = "2.0" },
                { name = "DashboardId", value = "" },
                { name = "DraftRequestParameters", value = { scopeId = "resource" } },
                { name = "Dimensions", isOptional = true },
                { name = "IsCompact", isOptional = true },
                { name = "PartTitle", value = "Peticiones al endpoint (últimas 24h)" },
                { name = "PartSubTitle", value = var.endpoint_name }
              ]
            }
          }
          # Widget 2 — Tasa de errores
          "1" = {
            position = { x = 6, y = 0, colSpan = 6, rowSpan = 4 }
            metadata = {
              type = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
              inputs = [
                { name = "resourceTypeMode", isOptional = true, value = "workspace" },
                { name = "ComponentId", isOptional = true, value = { SubscriptionId = "", ResourceGroup = var.workload_resource_group_name, Name = "", ResourceId = var.log_analytics_workspace_id } },
                {
                  name = "Query"
                  value = "AmlOnlineEndpointTrafficLog\n| where EndpointName == \"${var.endpoint_name}\"\n| summarize Total = count(), Errores = countif(ResponseCode >= 500) by bin(TimeGenerated, 1h)\n| extend TasaErrores = (Errores * 100.0) / Total\n| project TimeGenerated, TasaErrores\n| render timechart"
                },
                { name = "TimeRange", value = "P1D" },
                { name = "Version", value = "2.0" },
                { name = "PartTitle", value = "Tasa de errores del endpoint (%)" },
                { name = "PartSubTitle", value = "Umbral crítico: 5%" }
              ]
            }
          }
          # Widget 3 — Latencia media
          "2" = {
            position = { x = 0, y = 4, colSpan = 6, rowSpan = 4 }
            metadata = {
              type = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
              inputs = [
                { name = "resourceTypeMode", isOptional = true, value = "workspace" },
                { name = "ComponentId", isOptional = true, value = { SubscriptionId = "", ResourceGroup = var.workload_resource_group_name, Name = "", ResourceId = var.log_analytics_workspace_id } },
                {
                  name = "Query"
                  value = "AmlOnlineEndpointTrafficLog\n| where EndpointName == \"${var.endpoint_name}\"\n| summarize LatenciaMedia = avg(DurationMs) by bin(TimeGenerated, 1h)\n| render timechart"
                },
                { name = "TimeRange", value = "P1D" },
                { name = "Version", value = "2.0" },
                { name = "PartTitle", value = "Latencia media de respuesta (ms)" },
                { name = "PartSubTitle", value = "Umbral de aviso: 2000ms" }
              ]
            }
          }
          # Widget 4 — Jobs éxito vs fallo
          "3" = {
            position = { x = 6, y = 4, colSpan = 6, rowSpan = 4 }
            metadata = {
              type = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
              inputs = [
                { name = "resourceTypeMode", isOptional = true, value = "workspace" },
                { name = "ComponentId", isOptional = true, value = { SubscriptionId = "", ResourceGroup = var.workload_resource_group_name, Name = "", ResourceId = var.log_analytics_workspace_id } },
                {
                  name = "Query"
                  value = "AmlComputeJobEvent\n| where ClusterId contains \"${var.compute_cluster_name}\"\n| summarize count() by EventType, bin(TimeGenerated, 1d)\n| render barchart"
                },
                { name = "TimeRange", value = "P7D" },
                { name = "Version", value = "2.0" },
                { name = "PartTitle", value = "Jobs de entrenamiento - Éxitos vs Fallos" },
                { name = "PartSubTitle", value = "Últimos 7 días" }
              ]
            }
          }
          # Widget 5 — Versiones del modelo
          "4" = {
            position = { x = 0, y = 8, colSpan = 6, rowSpan = 4 }
            metadata = {
              type = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
              inputs = [
                { name = "resourceTypeMode", isOptional = true, value = "workspace" },
                { name = "ComponentId", isOptional = true, value = { SubscriptionId = "", ResourceGroup = var.workload_resource_group_name, Name = "", ResourceId = var.log_analytics_workspace_id } },
                {
                  name = "Query"
                  value = "AmlModelsEvent\n| where OperationName == \"Microsoft.MachineLearningServices/workspaces/models/versions/write\"\n| summarize Registros = count() by bin(TimeGenerated, 1d)\n| render timechart"
                },
                { name = "TimeRange", value = "P30D" },
                { name = "Version", value = "2.0" },
                { name = "PartTitle", value = "Versiones del modelo registradas" },
                { name = "PartSubTitle", value = "iris-classifier" }
              ]
            }
          }
          # Widget 6 — Estado del compute cluster
          "5" = {
            position = { x = 6, y = 8, colSpan = 6, rowSpan = 4 }
            metadata = {
              type = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
              inputs = [
                { name = "resourceTypeMode", isOptional = true, value = "workspace" },
                { name = "ComponentId", isOptional = true, value = { SubscriptionId = "", ResourceGroup = var.workload_resource_group_name, Name = "", ResourceId = var.log_analytics_workspace_id } },
                {
                  name = "Query"
                  value = "AmlComputeClusterEvent\n| where ClusterName == \"${var.compute_cluster_name}\"\n| summarize Eventos = count() by EventType, bin(TimeGenerated, 1h)\n| render barchart"
                },
                { name = "TimeRange", value = "P1D" },
                { name = "Version", value = "2.0" },
                { name = "PartTitle", value = "Estado del compute cluster" },
                { name = "PartSubTitle", value = var.compute_cluster_name }
              ]
            }
          }
          # Widget 7 — Coste acumulado
          "6" = {
            position = { x = 0, y = 12, colSpan = 12, rowSpan = 4 }
            metadata = {
              type = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
              inputs = [
                { name = "resourceTypeMode", isOptional = true, value = "workspace" },
                { name = "ComponentId", isOptional = true, value = { SubscriptionId = "", ResourceGroup = var.workload_resource_group_name, Name = "", ResourceId = var.log_analytics_workspace_id } },
                {
                  name = "Query"
                  value = "AmlComputeJobEvent\n| where ClusterId contains \"${var.compute_cluster_name}\"\n| where EventType == \"JobSucceeded\" or EventType == \"JobFailed\"\n| summarize TotalJobs = count(), JobsExitosos = countif(EventType == \"JobSucceeded\"), JobsFallidos = countif(EventType == \"JobFailed\") by bin(TimeGenerated, 1d)\n| render table"
                },
                { name = "TimeRange", value = "P30D" },
                { name = "Version", value = "2.0" },
                { name = "PartTitle", value = "Resumen de jobs de entrenamiento (últimos 30 días)" },
                { name = "PartSubTitle", value = "Total, exitosos y fallidos por día" }
              ]
            }
          }
        }
      }
    }
    metadata = {
      model = {
        timeRange = {
          value = { relative = { duration = 24, timeUnit = 1 } }
          type  = "MsPortalFx.Composition.Configuration.ValueTypes.TimeRange"
        }
        filterLocale = { value = "en-us" }
        filters      = { value = { MsPortalFx_TimeRange = { model = { format = "utc", granularity = "auto", relative = "24h" }, displayCache = { name = "UTC Time", value = "Past 24 hours" }, filteredPartIds = [] } } }
      }
    }
  })
}
