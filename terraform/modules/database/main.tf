
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Generate random password for SQL Server admin
resource "random_password" "sql_admin_password" {
  length  = 16
  special = true
}

# Azure SQL Server
resource "azurerm_mssql_server" "sql_server" {
  name                         = "${var.environment}-${var.database_name}-sql"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = random_password.sql_admin_password.result
  minimum_tls_version          = "1.2"

  # Azure AD authentication
  azuread_administrator {
    login_username = var.azuread_admin_login
    object_id      = var.azuread_admin_object_id
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.common_tags
}

# SQL Database
resource "azurerm_mssql_database" "database" {
  name           = "${var.environment}-${var.database_name}-db"
  server_id      = azurerm_mssql_server.sql_server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = var.max_size_gb
  sku_name       = var.database_sku
  zone_redundant = var.environment == "prod" ? true : false

  # Backup and restore settings
  short_term_retention_policy {
    retention_days = var.backup_retention_days
  }

  long_term_retention_policy {
    weekly_retention  = var.environment == "prod" ? "P1M" : null
    monthly_retention = var.environment == "prod" ? "P3M" : null
    yearly_retention  = var.environment == "prod" ? "P1Y" : null
    week_of_year      = var.environment == "prod" ? 1 : null
  }

  tags = var.common_tags
}

# Firewall rules
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Virtual Network Rule for App Service subnet
resource "azurerm_mssql_virtual_network_rule" "app_subnet_rule" {
  name      = "app-subnet-rule"
  server_id = azurerm_mssql_server.sql_server.id
  subnet_id = var.app_subnet_id
}

# Advanced Data Security
resource "azurerm_mssql_server_security_alert_policy" "security_alert" {
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mssql_server.sql_server.name
  state               = "Enabled"
  
  email_addresses = var.security_alert_emails
  retention_days  = 30
}

resource "azurerm_mssql_server_vulnerability_assessment" "vulnerability_assessment" {
  count                           = var.enable_vulnerability_assessment ? 1 : 0
  server_security_alert_policy_id = azurerm_mssql_server_security_alert_policy.security_alert.id
  storage_container_path          = "${var.storage_account_primary_blob_endpoint}${azurerm_storage_container.vulnerability_assessments[0].name}/"
  storage_account_access_key      = var.storage_account_primary_access_key

  recurring_scans {
    enabled                   = true
    email_subscription_admins = true
    emails                    = var.security_alert_emails
  }
}

# Storage container for vulnerability assessments
resource "azurerm_storage_container" "vulnerability_assessments" {
  count                 = var.enable_vulnerability_assessment ? 1 : 0
  name                  = "vulnerability-assessments"
  storage_account_name  = var.storage_account_name
  container_access_type = "private"
}

# Database auditing
resource "azurerm_mssql_database_extended_auditing_policy" "database_auditing" {
  database_id                             = azurerm_mssql_database.database.id
  storage_endpoint                        = var.storage_account_primary_blob_endpoint
  storage_account_access_key              = var.storage_account_primary_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = var.audit_retention_days
  log_monitoring_enabled                  = true
}

# Store connection string in Key Vault
resource "azurerm_key_vault_secret" "sql_connection_string" {
  name         = "sql-connection-string"
  value        = "Server=tcp:${azurerm_mssql_server.sql_server.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.database.name};Persist Security Info=False;User ID=${var.sql_admin_username};Password=${random_password.sql_admin_password.result};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  key_vault_id = var.key_vault_id

  depends_on = [azurerm_mssql_database.database]
}

# Store admin credentials in Key Vault
resource "azurerm_key_vault_secret" "sql_admin_username" {
  name         = "sql-admin-username"
  value        = var.sql_admin_username
  key_vault_id = var.key_vault_id
}

resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  value        = random_password.sql_admin_password.result
  key_vault_id = var.key_vault_id
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "sql_server_diagnostics" {
  name                       = "${azurerm_mssql_server.sql_server.name}-diagnostics"
  target_resource_id         = azurerm_mssql_server.sql_server.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "SQLSecurityAuditEvents"
  }

  enabled_log {
    category = "DevOpsOperationsAudit"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "database_diagnostics" {
  name                       = "${azurerm_mssql_database.database.name}-diagnostics"
  target_resource_id         = azurerm_mssql_database.database.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "SQLInsights"
  }

  enabled_log {
    category = "AutomaticTuning"
  }

  enabled_log {
    category = "QueryStoreRuntimeStatistics"
  }

  enabled_log {
    category = "QueryStoreWaitStatistics"
  }

  enabled_log {
    category = "Errors"
  }

  enabled_log {
    category = "DatabaseWaitStatistics"
  }

  enabled_log {
    category = "Timeouts"
  }

  enabled_log {
    category = "Blocks"
  }

  enabled_log {
    category = "Deadlocks"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}