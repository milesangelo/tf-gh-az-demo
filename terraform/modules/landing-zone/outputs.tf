
output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.landing_zone.name
}

output "resource_group_id" {
  description = "ID of the created resource group"
  value       = azurerm_resource_group.landing_zone.id
}

output "virtual_network_id" {
  description = "ID of the hub virtual network"
  value       = azurerm_virtual_network.hub_vnet.id
}

output "app_subnet_id" {
  description = "ID of the application subnet"
  value       = azurerm_subnet.app_subnet.id
}

output "db_subnet_id" {
  description = "ID of the database subnet"
  value       = azurerm_subnet.db_subnet.id
}

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.landing_zone_kv.id
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.landing_zone_kv.vault_uri
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.landing_zone_logs.id
}

output "application_insights_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.landing_zone_ai.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.landing_zone_ai.connection_string
  sensitive   = true
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.landing_zone_storage.name
}

output "location" {
  description = "Azure region where resources are deployed"
  value       = azurerm_resource_group.landing_zone.location
}