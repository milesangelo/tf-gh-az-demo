
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "app_name" {
  description = "Name of the application"
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

variable "sku_name" {
  description = "SKU for the App Service Plan"
  type        = string
  default     = "B1"
  validation {
    condition     = contains(["B1", "B2", "B3", "S1", "S2", "S3", "P1V2", "P2V2", "P3V2"], var.sku_name)
    error_message = "SKU must be a valid App Service Plan SKU."
  }
}

variable "app_subnet_id" {
  description = "ID of the subnet for VNet integration"
  type        = string
}

variable "key_vault_id" {
  description = "ID of the Key Vault"
  type        = string
}

variable "key_vault_name" {
  description = "Name of the Key Vault"
  type        = string
}

variable "application_insights_key" {
  description = "Application Insights instrumentation key"
  type        = string
  sensitive   = true
}

variable "application_insights_connection_string" {
  description = "Application Insights connection string"
  type        = string
  sensitive   = true
}

variable "custom_domain" {
  description = "Custom domain for the app service"
  type        = string
  default     = ""
}

variable "enable_autoscaling" {
  description = "Enable autoscaling for the app service"
  type        = bool
  default     = false
}

variable "autoscale_settings" {
  description = "Autoscaling configuration"
  type = object({
    min_instances              = number
    max_instances              = number
    default_instances          = number
    scale_out_cpu_threshold    = number
    scale_in_cpu_threshold     = number
  })
  default = {
    min_instances              = 1
    max_instances              = 3
    default_instances          = 1
    scale_out_cpu_threshold    = 70
    scale_in_cpu_threshold     = 25
  }
}

variable "enable_staging_slot" {
  description = "Enable staging deployment slot"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Number of days to retain application logs"
  type        = number
  default     = 7
}

variable "additional_app_settings" {
  description = "Additional app settings"
  type        = map(string)
  default     = {}
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}