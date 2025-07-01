terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    # These will be set via GitHub Actions or local override
    resource_group_name  = "weatherapi-demo-terraform-state-rg"
    storage_account_name = "weatherdemotf7314"
    container_name       = "tfstate"
    key                  = "bootstrap/terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azuread" {}

# Get current client configuration
data "azurerm_client_config" "current" {}

locals {
  demo_prefix = var.demo_prefix
  location = var.location
  
  common_tags = {
    Project     = "WeatherAPI-Demo"
    Owner       = var.owner
    Purpose     = "Demo"
    Environment = "bootstrap"
    ManagedBy   = "Terraform"
    CreatedBy   = "TerraformBootstrap"
  }
}

# Create the main application resource group via Terraform
resource "azurerm_resource_group" "app" {
  name     = "${local.demo_prefix}-app-rg"
  location = local.location
  tags     = local.common_tags
}

# Create resource groups for different environments
resource "azurerm_resource_group" "dev" {
  name     = "${local.demo_prefix}-dev-rg"
  location = local.location
  tags     = merge(local.common_tags, {
    Environment = "dev"
  })
}

resource "azurerm_resource_group" "staging" {
  name     = "${local.demo_prefix}-staging-rg"
  location = local.location
  tags     = merge(local.common_tags, {
    Environment = "staging"
  })
}

resource "azurerm_resource_group" "prod" {
  name     = "${local.demo_prefix}-prod-rg"
  location = local.location
  tags     = merge(local.common_tags, {
    Environment = "production"
  })
}

# Random string for unique resource names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Create a shared Key Vault for demo secrets
resource "azurerm_key_vault" "demo" {
  name                = "weather-kv-${random_string.suffix.result}"
  location            = local.location
  resource_group_name = azurerm_resource_group.app.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name           = var.key_vault_sku

  # Enable for deployment scenarios
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  
  # Enable soft delete and purge protection for production-like setup
  soft_delete_retention_days = 7
  purge_protection_enabled   = var.enable_purge_protection
  
  # Network access rules
  network_acls {
    default_action = "Allow"  # Allow access for demo - restrict in production
    bypass         = "AzureServices"
  }

  tags = local.common_tags
}

# Grant current service principal access to Key Vault
resource "azurerm_key_vault_access_policy" "current" {
  key_vault_id = azurerm_key_vault.demo.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List", 
    "Set",
    "Delete",
    "Backup",
    "Restore",
    "Recover"
  ]

  key_permissions = [
    "Get",
    "List",
    "Create",
    "Delete",
    "Update"
  ]
}

# Output important values for other Terraform configurations
output "app_resource_group_name" {
  description = "Name of the main application resource group"
  value       = azurerm_resource_group.app.name
}

output "app_resource_group_id" {
  description = "ID of the main application resource group"
  value       = azurerm_resource_group.app.id
}

output "dev_resource_group_name" {
  description = "Name of the dev environment resource group"
  value       = azurerm_resource_group.dev.name
}

output "dev_resource_group_id" {
  description = "ID of the dev environment resource group"
  value       = azurerm_resource_group.dev.id
}

output "staging_resource_group_name" {
  description = "Name of the staging environment resource group"
  value       = azurerm_resource_group.staging.name
}

output "staging_resource_group_id" {
  description = "ID of the staging environment resource group"
  value       = azurerm_resource_group.staging.id
}

output "prod_resource_group_name" {
  description = "Name of the production environment resource group"
  value       = azurerm_resource_group.prod.name
}

output "prod_resource_group_id" {
  description = "ID of the production environment resource group"
  value       = azurerm_resource_group.prod.id
}

output "location" {
  description = "Azure region for all resources"
  value       = local.location
}

output "common_tags" {
  description = "Common tags to apply to all resources"
  value       = local.common_tags
}

output "key_vault_id" {
  description = "ID of the shared Key Vault"
  value       = azurerm_key_vault.demo.id
}

output "key_vault_name" {
  description = "Name of the shared Key Vault"
  value       = azurerm_key_vault.demo.name
}

output "key_vault_uri" {
  description = "URI of the shared Key Vault"
  value       = azurerm_key_vault.demo.vault_uri
}

output "demo_prefix" {
  description = "Prefix used for naming resources"
  value       = local.demo_prefix
} 
