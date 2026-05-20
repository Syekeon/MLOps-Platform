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

# ============================================================
# Dashboard — MLOps Platform - Model Monitoring
# JSON exportado desde el portal y convertido al formato Terraform
# ============================================================
resource "azurerm_portal_dashboard" "mlops_monitoring" {
  name                = "dashboard-mlops-staging-weu-01"
  resource_group_name = var.workload_resource_group_name
  location            = var.location
  tags                = merge(var.tags, { hidden-title = "MLOps Platform - Model Monitoring" })

  dashboard_properties = jsonencode({
  "lenses": {
    "0": {
      "order": 0,
      "parts": {
        "0": {
          "position": {
            "x": 0,
            "y": 0,
            "colSpan": 15,
            "rowSpan": 1
          },
          "metadata": {
            "inputs": [],
            "type": "Extension/HubsExtension/PartType/MarkdownPart",
            "settings": {
              "content": {
                "content": "---",
                "title": "🖥️ INFRAESTRUCTURA",
                "subtitle": "Runner VM · Compute Cluster · Red",
                "markdownSource": 1,
                "markdownUri": ""
              }
            }
          }
        },
        "1": {
          "position": {
            "x": 0,
            "y": 1,
            "colSpan": 5,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "options",
                "isOptional": true
              },
              {
                "name": "sharedTimeRange",
                "isOptional": true
              }
            ],
            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/e19e0ebc-a9ed-4d6f-985f-f0a9fb8b544b/resourceGroups/RG-MLOPS-WORKLOAD-STG-WEU-01/providers/Microsoft.Compute/virtualMachines/VM-MLOPS-STG-RUNNER-WEU-01"
                        },
                        "name": "Percentage CPU",
                        "aggregationType": 4,
                        "namespace": "microsoft.compute/virtualmachines",
                        "metricVisualization": {
                          "displayName": "Percentage CPU",
                          "resourceDisplayName": "vm-mlops-stg-runner-weu-01"
                        }
                      }
                    ],
                    "title": "🖥️ Runner VM CPU",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideHoverCard": false,
                        "hideLabelNames": true
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      },
                      "disablePinning": true
                    }
                  }
                }
              }
            }
          }
        },
        "2": {
          "position": {
            "x": 5,
            "y": 1,
            "colSpan": 5,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "options",
                "isOptional": true
              },
              {
                "name": "sharedTimeRange",
                "isOptional": true
              }
            ],
            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/e19e0ebc-a9ed-4d6f-985f-f0a9fb8b544b/resourceGroups/RG-MLOPS-WORKLOAD-STG-WEU-01/providers/Microsoft.Compute/virtualMachines/VM-MLOPS-STG-RUNNER-WEU-01"
                        },
                        "name": "VmAvailabilityMetric",
                        "aggregationType": 4,
                        "namespace": "microsoft.compute/virtualmachines",
                        "metricVisualization": {
                          "displayName": "VM Availability Metric (Preview)",
                          "resourceDisplayName": "vm-mlops-stg-runner-weu-01"
                        }
                      }
                    ],
                    "title": "🖥️ Runner VM - Disponibilidad",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideHoverCard": false,
                        "hideLabelNames": true
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      },
                      "disablePinning": true
                    }
                  }
                }
              }
            }
          }
        },
        "3": {
          "position": {
            "x": 10,
            "y": 1,
            "colSpan": 5,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "resourceTypeMode",
                "isOptional": true
              },
              {
                "name": "ComponentId",
                "isOptional": true
              },
              {
                "name": "Scope",
                "value": {
                  "resourceIds": [
                    "/subscriptions/e19e0ebc-a9ed-4d6f-985f-f0a9fb8b544b/resourceGroups/rg-hub/providers/Microsoft.OperationalInsights/workspaces/log-hub-weu-01"
                  ]
                },
                "isOptional": true
              },
              {
                "name": "PartId",
                "value": "00988eba-0d89-43cd-b845-c3f3513381b5",
                "isOptional": true
              },
              {
                "name": "Version",
                "value": "2.0",
                "isOptional": true
              },
              {
                "name": "TimeRange",
                "value": "P1D",
                "isOptional": true
              },
              {
                "name": "DashboardId",
                "isOptional": true
              },
              {
                "name": "DraftRequestParameters",
                "isOptional": true
              },
              {
                "name": "Query",
                "value": "AmlComputeClusterEvent\n| where ClusterName == \"cpu-cluster-stg\"\n| summarize Eventos = count() by EventType, bin(TimeGenerated, 1h)\n| render barchart\n\n",
                "isOptional": true
              },
              {
                "name": "ControlType",
                "value": "FrameControlChart",
                "isOptional": true
              },
              {
                "name": "SpecificChart",
                "value": "StackedBar",
                "isOptional": true
              },
              {
                "name": "PartTitle",
                "value": "Analytics",
                "isOptional": true
              },
              {
                "name": "PartSubTitle",
                "value": "log-hub-weu-01",
                "isOptional": true
              },
              {
                "name": "Dimensions",
                "value": {
                  "xAxis": {
                    "name": "TimeGenerated",
                    "type": "datetime"
                  },
                  "yAxis": [
                    {
                      "name": "Eventos",
                      "type": "long"
                    }
                  ],
                  "splitBy": [
                    {
                      "name": "EventType",
                      "type": "string"
                    }
                  ],
                  "aggregation": "Sum"
                },
                "isOptional": true
              },
              {
                "name": "LegendOptions",
                "value": {
                  "isEnabled": true,
                  "position": "Bottom"
                },
                "isOptional": true
              },
              {
                "name": "IsQueryContainTimeRange",
                "value": false,
                "isOptional": true
              }
            ],
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart",
            "settings": {},
            "partHeader": {
              "title": "⚙️ Compute Cluster - Eventos por tipo",
              "subtitle": ""
            }
          }
        },
        "4": {
          "position": {
            "x": 0,
            "y": 4,
            "colSpan": 15,
            "rowSpan": 1
          },
          "metadata": {
            "inputs": [],
            "type": "Extension/HubsExtension/PartType/MarkdownPart",
            "settings": {
              "content": {
                "content": "---\n",
                "title": "🤖 ML PIPELINE",
                "subtitle": "Entrenamiento · Modelos · Jobse",
                "markdownSource": 1,
                "markdownUri": ""
              }
            }
          }
        },
        "5": {
          "position": {
            "x": 0,
            "y": 5,
            "colSpan": 5,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "resourceTypeMode",
                "isOptional": true
              },
              {
                "name": "ComponentId",
                "isOptional": true
              },
              {
                "name": "Scope",
                "value": {
                  "resourceIds": [
                    "/subscriptions/e19e0ebc-a9ed-4d6f-985f-f0a9fb8b544b/resourceGroups/rg-hub/providers/Microsoft.OperationalInsights/workspaces/log-hub-weu-01"
                  ]
                },
                "isOptional": true
              },
              {
                "name": "PartId",
                "value": "4521d37e-99f6-4c8a-a105-5d1a6331d655",
                "isOptional": true
              },
              {
                "name": "Version",
                "value": "2.0",
                "isOptional": true
              },
              {
                "name": "TimeRange",
                "value": "P1D",
                "isOptional": true
              },
              {
                "name": "DashboardId",
                "isOptional": true
              },
              {
                "name": "DraftRequestParameters",
                "isOptional": true
              },
              {
                "name": "Query",
                "value": "AmlModelsEvent\n| where OperationName == \"Microsoft.MachineLearningServices/workspaces/models/versions/write\"\n| summarize Registros = count() by bin(TimeGenerated, 1d)\n| render timechart\n",
                "isOptional": true
              },
              {
                "name": "ControlType",
                "value": "AnalyticsGrid",
                "isOptional": true
              },
              {
                "name": "SpecificChart",
                "isOptional": true
              },
              {
                "name": "PartTitle",
                "value": "Analytics",
                "isOptional": true
              },
              {
                "name": "PartSubTitle",
                "value": "log-hub-weu-01",
                "isOptional": true
              },
              {
                "name": "Dimensions",
                "isOptional": true
              },
              {
                "name": "LegendOptions",
                "isOptional": true
              },
              {
                "name": "IsQueryContainTimeRange",
                "value": false,
                "isOptional": true
              }
            ],
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart",
            "settings": {},
            "partHeader": {
              "title": "🤖 Versiones del modelo registradas (últimos 30 días)",
              "subtitle": ""
            }
          }
        },
        "6": {
          "position": {
            "x": 5,
            "y": 5,
            "colSpan": 5,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "resourceTypeMode",
                "isOptional": true
              },
              {
                "name": "ComponentId",
                "isOptional": true
              },
              {
                "name": "Scope",
                "value": {
                  "resourceIds": [
                    "/subscriptions/e19e0ebc-a9ed-4d6f-985f-f0a9fb8b544b/resourceGroups/rg-hub/providers/Microsoft.OperationalInsights/workspaces/log-hub-weu-01"
                  ]
                },
                "isOptional": true
              },
              {
                "name": "PartId",
                "value": "14c957d4-2aba-40bd-a18c-0f04bf533c9a",
                "isOptional": true
              },
              {
                "name": "Version",
                "value": "2.0",
                "isOptional": true
              },
              {
                "name": "TimeRange",
                "value": "P1D",
                "isOptional": true
              },
              {
                "name": "DashboardId",
                "isOptional": true
              },
              {
                "name": "DraftRequestParameters",
                "isOptional": true
              },
              {
                "name": "Query",
                "value": "AmlComputeJobEvent\n| where ClusterId contains \"cpu-cluster-stg\"\n| summarize count() by EventType, bin(TimeGenerated, 1d)\n| render barchart\n",
                "isOptional": true
              },
              {
                "name": "ControlType",
                "value": "AnalyticsGrid",
                "isOptional": true
              },
              {
                "name": "SpecificChart",
                "isOptional": true
              },
              {
                "name": "PartTitle",
                "value": "Analytics",
                "isOptional": true
              },
              {
                "name": "PartSubTitle",
                "value": "log-hub-weu-01",
                "isOptional": true
              },
              {
                "name": "Dimensions",
                "isOptional": true
              },
              {
                "name": "LegendOptions",
                "isOptional": true
              },
              {
                "name": "IsQueryContainTimeRange",
                "value": false,
                "isOptional": true
              }
            ],
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart",
            "settings": {},
            "partHeader": {
              "title": "🤖 Jobs de entrenamiento - Éxitos vs Fallos (últimos 7 días)",
              "subtitle": ""
            }
          }
        },
        "7": {
          "position": {
            "x": 10,
            "y": 5,
            "colSpan": 5,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "resourceTypeMode",
                "isOptional": true
              },
              {
                "name": "ComponentId",
                "isOptional": true
              },
              {
                "name": "Scope",
                "value": {
                  "resourceIds": [
                    "/subscriptions/e19e0ebc-a9ed-4d6f-985f-f0a9fb8b544b/resourceGroups/rg-hub/providers/Microsoft.OperationalInsights/workspaces/log-hub-weu-01"
                  ]
                },
                "isOptional": true
              },
              {
                "name": "PartId",
                "value": "1116f72c-0085-41c7-b103-544d27100d8e",
                "isOptional": true
              },
              {
                "name": "Version",
                "value": "2.0",
                "isOptional": true
              },
              {
                "name": "TimeRange",
                "value": "P1D",
                "isOptional": true
              },
              {
                "name": "DashboardId",
                "isOptional": true
              },
              {
                "name": "DraftRequestParameters",
                "isOptional": true
              },
              {
                "name": "Query",
                "value": "AmlComputeJobEvent\n| where ClusterId contains \"cpu-cluster-stg\"\n| where EventType == \"JobSucceeded\" or EventType == \"JobFailed\"\n| summarize TotalJobs = count(), Exitosos = countif(EventType == \"JobSucceeded\"), Fallidos = countif(EventType == \"JobFailed\") by bin(TimeGenerated, 1d)\n| render table\n",
                "isOptional": true
              },
              {
                "name": "ControlType",
                "value": "AnalyticsGrid",
                "isOptional": true
              },
              {
                "name": "SpecificChart",
                "isOptional": true
              },
              {
                "name": "PartTitle",
                "value": "Analytics",
                "isOptional": true
              },
              {
                "name": "PartSubTitle",
                "value": "log-hub-weu-01",
                "isOptional": true
              },
              {
                "name": "Dimensions",
                "isOptional": true
              },
              {
                "name": "LegendOptions",
                "isOptional": true
              },
              {
                "name": "IsQueryContainTimeRange",
                "value": false,
                "isOptional": true
              }
            ],
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart",
            "settings": {},
            "partHeader": {
              "title": "🤖 Resumen diario de jobs (últimos 30 días)",
              "subtitle": ""
            }
          }
        },
        "8": {
          "position": {
            "x": 0,
            "y": 8,
            "colSpan": 15,
            "rowSpan": 1
          },
          "metadata": {
            "inputs": [],
            "type": "Extension/HubsExtension/PartType/MarkdownPart",
            "settings": {
              "content": {
                "content": "---",
                "title": "🌐 ENDPOINTS",
                "subtitle": "Staging · Producción · Latencia",
                "markdownSource": 1,
                "markdownUri": ""
              }
            }
          }
        },
        "9": {
          "position": {
            "x": 0,
            "y": 9,
            "colSpan": 5,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "resourceTypeMode",
                "isOptional": true
              },
              {
                "name": "ComponentId",
                "isOptional": true
              },
              {
                "name": "Scope",
                "value": {
                  "resourceIds": [
                    "/subscriptions/e19e0ebc-a9ed-4d6f-985f-f0a9fb8b544b/resourceGroups/rg-hub/providers/Microsoft.OperationalInsights/workspaces/log-hub-weu-01"
                  ]
                },
                "isOptional": true
              },
              {
                "name": "PartId",
                "value": "1146b819-5d5d-4651-8e32-a253a711c6dd",
                "isOptional": true
              },
              {
                "name": "Version",
                "value": "2.0",
                "isOptional": true
              },
              {
                "name": "TimeRange",
                "value": "P1D",
                "isOptional": true
              },
              {
                "name": "DashboardId",
                "isOptional": true
              },
              {
                "name": "DraftRequestParameters",
                "isOptional": true
              },
              {
                "name": "Query",
                "value": "AmlOnlineEndpointTrafficLog\n| where EndpointName == \"iris-endpoint-stg-weu-01\"\n| summarize Peticiones = count() by bin(TimeGenerated, 1h)\n| render timechart\n",
                "isOptional": true
              },
              {
                "name": "ControlType",
                "value": "AnalyticsGrid",
                "isOptional": true
              },
              {
                "name": "SpecificChart",
                "isOptional": true
              },
              {
                "name": "PartTitle",
                "value": "Analytics",
                "isOptional": true
              },
              {
                "name": "PartSubTitle",
                "value": "log-hub-weu-01",
                "isOptional": true
              },
              {
                "name": "Dimensions",
                "isOptional": true
              },
              {
                "name": "LegendOptions",
                "isOptional": true
              },
              {
                "name": "IsQueryContainTimeRange",
                "value": false,
                "isOptional": true
              }
            ],
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart",
            "settings": {},
            "partHeader": {
              "title": "🌐 Peticiones al endpoint staging (últimas 24h)",
              "subtitle": ""
            }
          }
        },
        "10": {
          "position": {
            "x": 5,
            "y": 9,
            "colSpan": 5,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "resourceTypeMode",
                "isOptional": true
              },
              {
                "name": "ComponentId",
                "isOptional": true
              },
              {
                "name": "Scope",
                "value": {
                  "resourceIds": [
                    "/subscriptions/e19e0ebc-a9ed-4d6f-985f-f0a9fb8b544b/resourceGroups/rg-hub/providers/Microsoft.OperationalInsights/workspaces/log-hub-weu-01"
                  ]
                },
                "isOptional": true
              },
              {
                "name": "PartId",
                "value": "1517f35d-1254-4dcd-8151-240e7329155e",
                "isOptional": true
              },
              {
                "name": "Version",
                "value": "2.0",
                "isOptional": true
              },
              {
                "name": "TimeRange",
                "value": "P1D",
                "isOptional": true
              },
              {
                "name": "DashboardId",
                "isOptional": true
              },
              {
                "name": "DraftRequestParameters",
                "isOptional": true
              },
              {
                "name": "Query",
                "value": "AmlOnlineEndpointTrafficLog\n| where EndpointName == \"iris-endpoint-stg-weu-01\"\n| summarize LatenciaMedia = avg(RequestDurationMs) by bin(TimeGenerated, 1h)\n| render timechart\n",
                "isOptional": true
              },
              {
                "name": "ControlType",
                "value": "AnalyticsGrid",
                "isOptional": true
              },
              {
                "name": "SpecificChart",
                "isOptional": true
              },
              {
                "name": "PartTitle",
                "value": "Analytics",
                "isOptional": true
              },
              {
                "name": "PartSubTitle",
                "value": "log-hub-weu-01",
                "isOptional": true
              },
              {
                "name": "Dimensions",
                "isOptional": true
              },
              {
                "name": "LegendOptions",
                "isOptional": true
              },
              {
                "name": "IsQueryContainTimeRange",
                "value": false,
                "isOptional": true
              }
            ],
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart",
            "settings": {},
            "partHeader": {
              "title": "🌐 Latencia media endpoint staging (ms)",
              "subtitle": ""
            }
          }
        },
        "11": {
          "position": {
            "x": 10,
            "y": 9,
            "colSpan": 5,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "resourceTypeMode",
                "isOptional": true
              },
              {
                "name": "ComponentId",
                "isOptional": true
              },
              {
                "name": "Scope",
                "value": {
                  "resourceIds": [
                    "/subscriptions/e19e0ebc-a9ed-4d6f-985f-f0a9fb8b544b/resourceGroups/rg-hub/providers/Microsoft.OperationalInsights/workspaces/log-hub-weu-01"
                  ]
                },
                "isOptional": true
              },
              {
                "name": "PartId",
                "value": "0b334f9f-0a0d-400a-b412-43b7f962fdf4",
                "isOptional": true
              },
              {
                "name": "Version",
                "value": "2.0",
                "isOptional": true
              },
              {
                "name": "TimeRange",
                "value": "P1D",
                "isOptional": true
              },
              {
                "name": "DashboardId",
                "isOptional": true
              },
              {
                "name": "DraftRequestParameters",
                "isOptional": true
              },
              {
                "name": "Query",
                "value": "AmlOnlineEndpointTrafficLog\n| where EndpointName == \"iris-endpoint-stg-weu-01\"\n| summarize Total = count(), Errores = countif(ResponseCode >= 500) by bin(TimeGenerated, 1h)\n| extend TasaErrores = (Errores * 100.0) / Total\n| project TimeGenerated, TasaErrores\n| render timechart\n",
                "isOptional": true
              },
              {
                "name": "ControlType",
                "value": "AnalyticsGrid",
                "isOptional": true
              },
              {
                "name": "SpecificChart",
                "isOptional": true
              },
              {
                "name": "PartTitle",
                "value": "Analytics",
                "isOptional": true
              },
              {
                "name": "PartSubTitle",
                "value": "log-hub-weu-01",
                "isOptional": true
              },
              {
                "name": "Dimensions",
                "isOptional": true
              },
              {
                "name": "LegendOptions",
                "isOptional": true
              },
              {
                "name": "IsQueryContainTimeRange",
                "value": false,
                "isOptional": true
              }
            ],
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart",
            "settings": {},
            "partHeader": {
              "title": "🌐 Tasa de errores endpoint staging (%)",
              "subtitle": ""
            }
          }
        },
        "12": {
          "position": {
            "x": 0,
            "y": 12,
            "colSpan": 15,
            "rowSpan": 1
          },
          "metadata": {
            "inputs": [],
            "type": "Extension/HubsExtension/PartType/MarkdownPart",
            "settings": {
              "content": {
                "content": "---\n",
                "title": "💰 COSTES",
                "subtitle": "Cómputo utilizado · Presupuesto",
                "markdownSource": 1,
                "markdownUri": ""
              }
            }
          }
        },
        "13": {
          "position": {
            "x": 0,
            "y": 13,
            "colSpan": 15,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [
              {
                "name": "resourceTypeMode",
                "isOptional": true
              },
              {
                "name": "ComponentId",
                "isOptional": true
              },
              {
                "name": "Scope",
                "value": {
                  "resourceIds": [
                    "/subscriptions/e19e0ebc-a9ed-4d6f-985f-f0a9fb8b544b/resourceGroups/rg-hub/providers/Microsoft.OperationalInsights/workspaces/log-hub-weu-01"
                  ]
                },
                "isOptional": true
              },
              {
                "name": "PartId",
                "value": "78c2dbf9-354a-4b8a-9123-7e1a7a125348",
                "isOptional": true
              },
              {
                "name": "Version",
                "value": "2.0",
                "isOptional": true
              },
              {
                "name": "TimeRange",
                "value": "P1D",
                "isOptional": true
              },
              {
                "name": "DashboardId",
                "isOptional": true
              },
              {
                "name": "DraftRequestParameters",
                "isOptional": true
              },
              {
                "name": "Query",
                "value": "AmlComputeJobEvent\n| where ClusterId contains \"cpu-cluster-stg\"\n| where EventType == \"JobSucceeded\" or EventType == \"JobFailed\"\n| summarize TotalJobs = count() by bin(TimeGenerated, 1d)\n| render timechart\n",
                "isOptional": true
              },
              {
                "name": "ControlType",
                "value": "AnalyticsGrid",
                "isOptional": true
              },
              {
                "name": "SpecificChart",
                "isOptional": true
              },
              {
                "name": "PartTitle",
                "value": "Analytics",
                "isOptional": true
              },
              {
                "name": "PartSubTitle",
                "value": "log-hub-weu-01",
                "isOptional": true
              },
              {
                "name": "Dimensions",
                "isOptional": true
              },
              {
                "name": "LegendOptions",
                "isOptional": true
              },
              {
                "name": "IsQueryContainTimeRange",
                "value": false,
                "isOptional": true
              }
            ],
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart",
            "settings": {},
            "partHeader": {
              "title": "💰 Jobs de entrenamiento ejecutados (últimos 30 días)",
              "subtitle": ""
            }
          }
        }
      }
    }
  },
  "metadata": {
    "model": {
      "timeRange": {
        "value": {
          "relative": {
            "duration": 24,
            "timeUnit": 1
          }
        },
        "type": "MsPortalFx.Composition.Configuration.ValueTypes.TimeRange"
      },
      "filterLocale": {
        "value": "en-us"
      },
      "filters": {
        "value": {
          "MsPortalFx_TimeRange": {
            "model": {
              "format": "utc",
              "granularity": "auto",
              "relative": "24h"
            },
            "displayCache": {
              "name": "UTC Time",
              "value": "Past 24 hours"
            },
            "filteredPartIds": [
              "StartboardPart-MonitorChartPart-69931583-9434-4b70-8ad6-b3842a95b609",
              "StartboardPart-MonitorChartPart-69931583-9434-4b70-8ad6-b3842a95b60b",
              "StartboardPart-LogsDashboardPart-69931583-9434-4b70-8ad6-b3842a95b60d",
              "StartboardPart-LogsDashboardPart-69931583-9434-4b70-8ad6-b3842a95b611",
              "StartboardPart-LogsDashboardPart-69931583-9434-4b70-8ad6-b3842a95b613",
              "StartboardPart-LogsDashboardPart-69931583-9434-4b70-8ad6-b3842a95b615",
              "StartboardPart-LogsDashboardPart-69931583-9434-4b70-8ad6-b3842a95b617",
              "StartboardPart-LogsDashboardPart-69931583-9434-4b70-8ad6-b3842a95b619",
              "StartboardPart-LogsDashboardPart-69931583-9434-4b70-8ad6-b3842a95b61b",
              "StartboardPart-LogsDashboardPart-69931583-9434-4b70-8ad6-b3842a95b61d"
            ]
          }
        }
      }
    }
  }
})
}
