
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "database_name" {
  description = "Name of the database"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "sql_admin_username" {
  description = "SQL Server administrator username"
  type        = string
  default     = "sqladmin"
}

variable "azuread_admin_login" {
  description = "Azure AD admin login name"
  type        = string
}

variable "azuread_admin_object_id" {
  description = "Azure AD admin object ID"
  type        = string
}

variable "database_sku" {
  description = "Database SKU"
  type        = string
  default     = "Basic"
  validation {
    condition = contains([
      "Basic", "S0", "S1", "S2", "S3", "S4", "S6", "S7", "S9", "S12",
      "P1", "P2", "P4", "P6", "P11", "P15",
      "GP_Gen5_2", "GP_Gen5_4", "GP_Gen5_8", "GP_Gen5_16", "GP_Gen5_32",
      "BC_Gen5_2", "BC_Gen5_4", "BC_Gen5_8", "BC_Gen5_16", "BC_Gen5_32"
    ], var.database_sku)
    error_message = "Database SKU must be a valid Azure SQL Database SKU."
  }
}

variable "max_size_gb" {
  description = "Maximum size of the database in GB"
  type        = number
  default     = 2
}

variable "app_subnet_id" {
  description = "ID of the application subnet for VNet integration"
  type        = string
}

variable "key_vault_id" {
  description = "ID of the Key Vault for storing secrets"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account for auditing"
  type        = string
}

variable "storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint of the storage account"
  type        = string
}

variable "storage_account_primary_access_key" {
  description = "Primary access key of the storage account"
  type        = string
  sensitive   = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "Backup retention days must be between 7 and 35."
  }
}

variable "audit_retention_days" {
  description = "Number of days to retain audit logs"
  type        = number
  default     = 90
}

variable "security_alert_emails" {
  description = "List of email addresses for security alerts"
  type        = list(string)
  default     = []
}

variable "enable_vulnerability_assessment" {
  description = "Enable vulnerability assessment"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
