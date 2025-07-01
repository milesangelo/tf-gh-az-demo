
output "app_service_name" {
  description = "Name of the App Service"
  value       = azurerm_linux_web_app.app.name
}

output "app_service_id" {
  description = "ID of the App Service"
  value       = azurerm_linux_web_app.app.id
}

output "app_service_url" {
  description = "URL of the App Service"
  value       = "https://${azurerm_linux_web_app.app.default_hostname}"
}

output "app_service_hostname" {
  description = "Default hostname of the App Service"
  value       = azurerm_linux_web_app.app.default_hostname
}

output "app_service_plan_id" {
  description = "ID of the App Service Plan"
  value       = azurerm_service_plan.app_plan.id
}

output "app_service_identity" {
  description = "Managed identity of the App Service"
  value = {
    principal_id = azurerm_linux_web_app.app.identity[0].principal_id
    tenant_id    = azurerm_linux_web_app.app.identity[0].tenant_id
  }
}

output "staging_slot_name" {
  description = "Name of the staging slot"
  value       = var.enable_staging_slot ? azurerm_linux_web_app_slot.staging[0].name : null
}

output "staging_slot_url" {
  description = "URL of the staging slot"
  value       = var.enable_staging_slot ? "https://${azurerm_linux_web_app.app.name}-staging.azurewebsites.net" : null
}