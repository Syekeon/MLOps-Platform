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
    action_groups = [var.shared_action_group_id]
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
    action_groups = [var.shared_action_group_id]
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
    action_groups = [var.shared_action_group_id]
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
    action_groups = [var.shared_action_group_id]
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
    action_groups = [var.shared_action_group_id]
  }
}

# ============================================================
# Alerta 6 — Runner VM apagada
# ============================================================
resource "azurerm_monitor_metric_alert" "runner_vm_down" {
  name                = "alert-mlops-runner-vm-down"
  resource_group_name = var.workload_resource_group_name
  description         = "La runner VM de GitHub Actions está apagada. Los pipelines de CI/CD no podrán ejecutarse."
  severity            = 0
  enabled             = true
  tags                = var.tags
  scopes = [
    "/subscriptions/${var.subscription_id}/resourceGroups/${var.workload_resource_group_name}/providers/Microsoft.Compute/virtualMachines/${var.runner_vm_name}"
  ]
  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "VmAvailabilityMetric"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1
  }
  action {
    action_group_id = var.shared_action_group_id
  }
}

# ============================================================
# Alerta 7 — Endpoint prod sin tráfico en 1 hora
# ============================================================
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "endpoint_prod_no_traffic" {
  name                = "alert-mlops-endpoint-prod-no-traffic"
  resource_group_name = var.workload_resource_group_name
  location            = var.location
  tags                = var.tags
  display_name         = "[MLOps][AVISO] Endpoint producción sin tráfico"
  description          = "El endpoint de producción lleva más de 1 hora sin recibir peticiones."
  severity             = 1
  enabled              = true
  evaluation_frequency = "PT1H"
  window_duration      = "PT1H"
  scopes = [var.log_analytics_workspace_id]
  criteria {
    query = <<-QUERY
      AmlOnlineEndpointTrafficLog
      | where EndpointName == "${var.endpoint_prod_name}"
      | summarize RequestCount = count() by bin(TimeGenerated, 1h)
    QUERY
    time_aggregation_method = "Count"
    threshold               = 1
    operator                = "LessThan"
    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }
  action {
    action_groups = [var.shared_action_group_id]
  }
}

# ============================================================
# Alerta 8 — Endpoint prod con errores 4xx > 10%
# ============================================================
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "endpoint_prod_4xx" {
  name                = "alert-mlops-endpoint-prod-4xx"
  resource_group_name = var.workload_resource_group_name
  location            = var.location
  tags                = var.tags
  display_name         = "[MLOps][AVISO] Endpoint producción con errores 4xx altos"
  description          = "Más del 10% de las peticiones al endpoint de producción devuelven errores 4xx."
  severity             = 1
  enabled              = true
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  scopes = [var.log_analytics_workspace_id]
  criteria {
    query = <<-QUERY
      AmlOnlineEndpointTrafficLog
      | where EndpointName == "${var.endpoint_prod_name}"
      | summarize
          TotalRequests = count(),
          Error4xx = countif(ResponseCode >= 400 and ResponseCode < 500)
        by bin(TimeGenerated, 5m)
      | where TotalRequests > 0
      | extend ErrorRate4xx = (Error4xx * 100.0) / TotalRequests
      | where ErrorRate4xx > 10
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
    action_groups = [var.shared_action_group_id]
  }
}

# ============================================================
# Alerta 9 — Presupuesto mensual (80% y 100%)
# ============================================================
resource "azurerm_consumption_budget_resource_group" "mlops_budget" {
  name              = "budget-mlops-stg-weu-01"
  resource_group_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.workload_resource_group_name}"
  amount     = var.monthly_budget_amount
  time_grain = "Monthly"
  time_period {
    start_date = "2026-05-01T00:00:00Z"
  }
  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = var.alert_emails
    contact_groups = [var.shared_action_group_id]
  }
  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = var.alert_emails
    contact_groups = [var.shared_action_group_id]
  }
}

# ============================================================
# Dashboard — MLOps Platform - Model Monitoring
# 4 secciones: Infraestructura → ML Pipeline → Endpoints → Costes
# ============================================================
resource "azurerm_portal_dashboard" "mlops_monitoring" {
  name                = "dashboard-mlops-staging-weu-01"
  resource_group_name = var.workload_resource_group_name
  location            = var.location
  tags                = merge(var.tags, { hidden-title = "MLOps Platform - Model Monitoring" })

  dashboard_properties = jsonencode({
    lenses = {
      # ── Sección 1: INFRAESTRUCTURA ──────────────────────
      "0" = {
        order = 0
        parts = {
          # Runner VM disponibilidad
          "0" = {
            position = { x = 0, y = 0, colSpan = 4, rowSpan = 3 }
            metadata = {
              type = "Extension/Microsoft_Azure_Monitoring/PartType/MetricsChartPart"
              inputs = [
                { name = "resourceId", value = "/subscriptions/${var.subscription_id}/resourceGroups/${var.workload_resource_group_name}/providers/Microsoft.Compute/virtualMachines/${var.runner_vm_name}" },
                { name = "timespan", value = { relative = { duration = 86400000 } } },
                { name = "chartType", value = 0 },
                { name = "metrics", value = [{ resourceMetadata = { id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.workload_resource_group_name}/providers/Microsoft.Compute/virtualMachines/${var.runner_vm_name}" }, name = "VmAvailabilityMetric", aggregationType = 4, metricVisualization = { displayName = "Disponibilidad" } }] },
                { name = "title", value = "🖥️ Runner VM - Disponibilidad" }
              ]
            }
          }
          # Runner VM CPU
          "1" = {
            position = { x = 4, y = 0, colSpan = 4, rowSpan = 3 }
            metadata = {
              type = "Extension/Microsoft_Azure_Monitoring/PartType/MetricsChartPart"
              inputs = [
                { name = "resourceId", value = "/subscriptions/${var.subscription_id}/resourceGroups/${var.workload_resource_group_name}/providers/Microsoft.Compute/virtualMachines/${var.runner_vm_name}" },
                { name = "timespan", value = { relative = { duration = 86400000 } } },
                { name = "chartType", value = 0 },
                { name = "metrics", value = [{ resourceMetadata = { id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.workload_resource_group_name}/providers/Microsoft.Compute/virtualMachines/${var.runner_vm_name}" }, name = "Percentage CPU", aggregationType = 4, metricVisualization = { displayName = "CPU (%)" } }] },
                { name = "title", value = "🖥️ Runner VM - CPU (%)" }
              ]
            }
          }
          # Compute cluster eventos
          "2" = {
            position = { x = 8, y = 0, colSpan = 4, rowSpan = 3 }
            metadata = {
              type = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
              inputs = [
                { name = "resourceTypeMode", isOptional = true, value = "workspace" },
                { name = "ComponentId", isOptional = true, value = { SubscriptionId = "", ResourceGroup = var.workload_resource_group_name, Name = "", ResourceId = var.log_analytics_workspace_id } },
                { name = "Query", value = "AmlComputeClusterEvent\n| where ClusterName == \"${var.compute_cluster_name}\"\n| summarize Eventos = count() by EventType, bin(TimeGenerated, 1h)\n| render barchart" },
                { name = "TimeRange", value = "P1D" },
                { name = "Version", value = "2.0" },
                { name = "PartTitle", value = "⚙️ Compute Cluster - Estado" },
                { name = "PartSubTitle", value = var.compute_cluster_name }
              ]
            }
          }
        }
      }
      # ── Sección 2: ML PIPELINE ──────────────────────────
      "1" = {
        order = 1
        parts = {
          # Jobs éxito vs fallo
          "0" = {
            position = { x = 0, y = 3, colSpan = 6, rowSpan = 4 }
            metadata = {
              type = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
              inputs = [
                { name = "resourceTypeMode", isOptional = true, value = "workspace" },
                { name = "ComponentId", isOptional = true, value = { SubscriptionId = "", ResourceGroup = var.workload_resource_group_name, Name = "", ResourceId = var.log_analytics_workspace_id } },
                { name = "Query", value = "AmlComputeJobEvent\n| where ClusterId contains \"${var.compute_cluster_name}\"\n| summarize count() by EventType, bin(TimeGenerated, 1d)\n| render barchart" },
                { name = "TimeRange", value = "P7D" },
                { name = "Version", value = "2.0" },
                { name = "PartTitle", value = "🤖 Jobs de entrenamiento - Éxitos vs Fallos" },
                { name = "PartSubTitle", value = "Últimos 7 días" }
              ]
            }
          }
          # Modelos registrados
          "1" = {
            position = { x = 6, y = 3, colSpan = 6, rowSpan = 4 }
            metadata = {
              type = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
              inputs = [
                { name = "resourceTypeMode", isOptional = true, value = "workspace" },
                { name = "ComponentId", isOptional = true, value = { SubscriptionId = "", ResourceGroup = var.workload_resource_group_name, Name = "", ResourceId = var.log_analytics_workspace_id } },
                { name = "Query", value = "AmlModelsEvent\n| where OperationName == \"Microsoft.MachineLearningServices/workspaces/models/versions/write\"\n| summarize Registros = count() by bin(TimeGenerated, 1d)\n| render timechart" },
                { name = "TimeRange", value = "P30D" },
                { name = "Version", value = "2.0" },
                { name = "PartTitle", value = "🤖 Versiones del modelo registradas" },
                { name = "PartSubTitle", value = "Últimos 30 días" }
              ]
            }
          }
          # Resumen jobs tabla
          "2" = {
            position = { x = 0, y = 7, colSpan = 12, rowSpan = 3 }
            metadata = {
              type = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
              inputs = [
                { name = "resourceTypeMode", isOptional = true, value = "workspace" },
                { name = "ComponentId", isOptional = true, value = { SubscriptionId = "", ResourceGroup = var.workload_resource_group_name, Name = "", ResourceId = var.log_analytics_workspace_id } },
                { name = "Query", value = "AmlComputeJobEvent\n| where ClusterId contains \"${var.compute_cluster_name}\"\n| where EventType == \"JobSucceeded\" or EventType == \"JobFailed\"\n| summarize TotalJobs = count(), Exitosos = countif(EventType == \"JobSucceeded\"), Fallidos = countif(EventType == \"JobFailed\") by bin(TimeGenerated, 1d)\n| render table" },
                { name = "TimeRange", value = "P30D" },
                { name = "Version", value = "2.0" },
                { name = "PartTitle", value = "🤖 Resumen diario de jobs (últimos 30 días)" },
                { name = "PartSubTitle", value = "Total · Exitosos · Fallidos" }
              ]
            }
          }
        }
      }
      # ── Sección 3: ENDPOINTS ────────────────────────────
      "2" = {
        order = 2
        parts = {
          # Peticiones staging
          "0" = {
            position = { x = 0, y = 10, colSpan = 4, rowSpan = 4 }
            metadata = {
              type = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
              inputs = [
                { name = "resourceTypeMode", isOptional = true, value = "workspace" },
                { name = "ComponentId", isOptional = true, value = { SubscriptionId = "", ResourceGroup = var.workload_resource_group_name, Name = "", ResourceId = var.log_analytics_workspace_id } },
                { name = "Query", value = "AmlOnlineEndpointTrafficLog\n| where EndpointName == \"${var.endpoint_name}\"\n| summarize Peticiones = count() by bin(TimeGenerated, 1h)\n| render timechart" },
                { name = "TimeRange", value = "P1D" },
                { name = "Version", value = "2.0" },
                { name = "PartTitle", value = "🌐 Peticiones al endpoint staging" },
                { name = "PartSubTitle", value = var.endpoint_name }
              ]
            }
          }
          # Tasa errores staging
          "1" = {
            position = { x = 4, y = 10, colSpan = 4, rowSpan = 4 }
            metadata = {
              type = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
              inputs = [
                { name = "resourceTypeMode", isOptional = true, value = "workspace" },
                { name = "ComponentId", isOptional = true, value = { SubscriptionId = "", ResourceGroup = var.workload_resource_group_name, Name = "", ResourceId = var.log_analytics_workspace_id } },
                { name = "Query", value = "AmlOnlineEndpointTrafficLog\n| where EndpointName == \"${var.endpoint_name}\"\n| summarize Total = count(), Errores = countif(ResponseCode >= 500) by bin(TimeGenerated, 1h)\n| extend TasaErrores = (Errores * 100.0) / Total\n| project TimeGenerated, TasaErrores\n| render timechart" },
                { name = "TimeRange", value = "P1D" },
                { name = "Version", value = "2.0" },
                { name = "PartTitle", value = "🌐 Tasa de errores staging (%)" },
                { name = "PartSubTitle", value = "Umbral crítico: 5%" }
              ]
            }
          }
          # Latencia staging
          "2" = {
            position = { x = 8, y = 10, colSpan = 4, rowSpan = 4 }
            metadata = {
              type = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
              inputs = [
                { name = "resourceTypeMode", isOptional = true, value = "workspace" },
                { name = "ComponentId", isOptional = true, value = { SubscriptionId = "", ResourceGroup = var.workload_resource_group_name, Name = "", ResourceId = var.log_analytics_workspace_id } },
                { name = "Query", value = "AmlOnlineEndpointTrafficLog\n| where EndpointName == \"${var.endpoint_name}\"\n| summarize LatenciaMedia = avg(RequestDurationMs) by bin(TimeGenerated, 1h)\n| render timechart" },
                { name = "TimeRange", value = "P1D" },
                { name = "Version", value = "2.0" },
                { name = "PartTitle", value = "🌐 Latencia media staging (ms)" },
                { name = "PartSubTitle", value = "Umbral de aviso: 2000ms" }
              ]
            }
          }
        }
      }
      # ── Sección 4: COSTES ───────────────────────────────
      "3" = {
        order = 3
        parts = {
          # Resumen coste indirecto por jobs
          "0" = {
            position = { x = 0, y = 14, colSpan = 12, rowSpan = 4 }
            metadata = {
              type = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
              inputs = [
                { name = "resourceTypeMode", isOptional = true, value = "workspace" },
                { name = "ComponentId", isOptional = true, value = { SubscriptionId = "", ResourceGroup = var.workload_resource_group_name, Name = "", ResourceId = var.log_analytics_workspace_id } },
                { name = "Query", value = "AmlComputeJobEvent\n| where ClusterId contains \"${var.compute_cluster_name}\"\n| where EventType == \"JobSucceeded\" or EventType == \"JobFailed\"\n| extend DuracionMin = todouble(split(tostring(parse_json(Details).runDuration), \":\")[1])\n| summarize TotalJobs = count(), TiempoTotalMin = sum(DuracionMin) by bin(TimeGenerated, 1d)\n| render table" },
                { name = "TimeRange", value = "P30D" },
                { name = "Version", value = "2.0" },
                { name = "PartTitle", value = "💰 Tiempo de cómputo utilizado (últimos 30 días)" },
                { name = "PartSubTitle", value = "Total jobs · Tiempo total en minutos" }
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
