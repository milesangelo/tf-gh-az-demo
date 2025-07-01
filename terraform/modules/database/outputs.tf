
output "sql_server_name" {
  description = "Name of the SQL Server"
  value       = azurerm_mssql_server.sql_server.name
}

output "sql_server_id" {
  description = "ID of the SQL Server"
  value       = azurerm_mssql_server.sql_server.id
}

output "sql_server_fqdn" {
  description = "Fully qualified domain name of the SQL Server"
  value       = azurerm_mssql_server.sql_server.fully_qualified_domain_name
}

output "database_name" {
  description = "Name of the database"
  value       = azurerm_mssql_database.database.name
}

output "database_id" {
  description = "ID of the database"
  value       = azurerm_mssql_database.database.id
}

output "connection_string_secret_name" {
  description = "Name of the Key Vault secret containing the connection string"
  value       = azurerm_key_vault_secret.sql_connection_string.name
}

output "admin_username_secret_name" {
  description = "Name of the Key Vault secret containing the admin username"
  value       = azurerm_key_vault_secret.sql_admin_username.name
}

output "admin_password_secret_name" {
  description = "Name of the Key Vault secret containing the admin password"
  value       = azurerm_key_vault_secret.sql_admin_password.name
}

output "sql_server_identity" {
  description = "Managed identity of the SQL Server"
  value = {
    principal_id = azurerm_mssql_server.sql_server.identity[0].principal_id
    tenant_id    = azurerm_mssql_server.sql_server.identity[0].tenant_id
  }
}