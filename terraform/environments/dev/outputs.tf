
output "resource_group_name" {
  description = "Name of the created resource group"
  value       = module.landing_zone.resource_group_name
}

output "app_service_url" {
  description = "URL of the deployed application"
  value       = module.app_service.app_service_url
}

output "staging_slot_url" {
  description = "URL of the staging slot"
  value       = module.app_service.staging_slot_url
}

output "sql_server_name" {
  description = "Name of the SQL Server"
  value       = module.database.sql_server_name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.landing_zone.key_vault_uri
}

output "application_insights_key" {
  description = "Application Insights instrumentation key"
  value       = module.landing_zone.application_insights_key
  sensitive   = true
}