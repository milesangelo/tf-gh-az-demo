output "resource_group_name" {
  description = "Name of the resource group"
  value       = data.azurerm_resource_group.main.name
}

output "app_service_url" {
  description = "URL of the App Service"
  value       = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "app_service_name" {
  description = "Name of the App Service"
  value       = azurerm_linux_web_app.main.name
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = data.azurerm_key_vault.shared.name
}

output "environment" {
  description = "Environment name"
  value       = local.environment
}