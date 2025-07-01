variable "demo_prefix" {
  description = "Prefix for resource naming"
  type        = string
  default     = "weatherapi-demo"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US 2"
}

variable "owner" {
  description = "Owner tag for resources"
  type        = string
  default     = "mvendetti"
}

variable "enable_purge_protection" {
  description = "Enable purge protection on Key Vault (set to false for demo cleanup)"
  type        = bool
  default     = false
}

variable "key_vault_sku" {
  description = "SKU for Key Vault"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.key_vault_sku)
    error_message = "Key Vault SKU must be either 'standard' or 'premium'."
  }
} 