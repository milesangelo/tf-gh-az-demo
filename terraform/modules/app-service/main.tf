
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# App Service Plan
resource "azurerm_service_plan" "app_plan" {
  name                = "${var.environment}-${var.app_name}-plan"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.sku_name

  tags = var.common_tags
}

# App Service
resource "azurerm_linux_web_app" "app" {
  name                = "${var.environment}-${var.app_name}-app"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.app_plan.id

  site_config {
    always_on         = var.environment == "prod" ? true : false
    health_check_path = "/health"
    
    application_stack {
      dotnet_version = "8.0"
    }

    # Enable Application Insights
    application_insights_connection_string = var.application_insights_connection_string
    application_insights_key               = var.application_insights_key
  }

  app_settings = merge({
    "ASPNETCORE_ENVIRONMENT"                   = var.environment == "prod" ? "Production" : title(var.environment)
    "APPLICATIONINSIGHTS_CONNECTION_STRING"    = var.application_insights_connection_string
    "ApplicationInsights__ConnectionString"    = var.application_insights_connection_string
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE"     = "false"
    "WEBSITE_ENABLE_SYNC_UPDATE_SITE"         = "true"
    "ConnectionStrings__DefaultConnection"     = "@Microsoft.KeyVault(VaultName=${var.key_vault_name};SecretName=sql-connection-string)"
  }, var.additional_app_settings)

  connection_string {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = "@Microsoft.KeyVault(VaultName=${var.key_vault_name};SecretName=sql-connection-string)"
  }

  identity {
    type = "SystemAssigned"
  }

  # Network configuration
  virtual_network_subnet_id = var.app_subnet_id

  logs {
    detailed_error_messages = var.environment != "prod"
    failed_request_tracing  = var.environment != "prod"
    
    application_logs {
      file_system_level = "Information"
    }

    http_logs {
      file_system {
        retention_in_days = var.log_retention_days
        retention_in_mb   = 35
      }
    }
  }

  tags = var.common_tags
}

# Grant App Service access to Key Vault
resource "azurerm_key_vault_access_policy" "app_service_policy" {
  key_vault_id = var.key_vault_id
  tenant_id    = azurerm_linux_web_app.app.identity[0].tenant_id
  object_id    = azurerm_linux_web_app.app.identity[0].principal_id

  secret_permissions = [
    "Get", "List"
  ]
}

# Custom domain and SSL (optional)
resource "azurerm_app_service_custom_hostname_binding" "app_hostname" {
  count               = var.custom_domain != "" ? 1 : 0
  hostname            = var.custom_domain
  app_service_name    = azurerm_linux_web_app.app.name
  resource_group_name = var.resource_group_name
}

# Auto-scaling configuration
resource "azurerm_monitor_autoscale_setting" "app_autoscale" {
  count               = var.enable_autoscaling ? 1 : 0
  name                = "${var.environment}-${var.app_name}-autoscale"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_service_plan.app_plan.id

  profile {
    name = "defaultProfile"

    capacity {
      default = var.autoscale_settings.default_instances
      minimum = var.autoscale_settings.min_instances
      maximum = var.autoscale_settings.max_instances
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.app_plan.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = var.autoscale_settings.scale_out_cpu_threshold
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.app_plan.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = var.autoscale_settings.scale_in_cpu_threshold
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  tags = var.common_tags
}

# Deployment slots for staging
resource "azurerm_linux_web_app_slot" "staging" {
  count          = var.enable_staging_slot ? 1 : 0
  name           = "staging"
  app_service_id = azurerm_linux_web_app.app.id

  site_config {
    always_on = false
    
    application_stack {
      dotnet_version = "8.0"
    }
  }

  app_settings = merge({
    "ASPNETCORE_ENVIRONMENT"                = "Staging"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.application_insights_connection_string
  }, var.additional_app_settings)

  identity {
    type = "SystemAssigned"
  }

  tags = var.common_tags
}