terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "weatherapi-demo-terraform-state-rg"
    storage_account_name = "weatherdemotf7314"
    container_name       = "tfstate"
    key                  = "dev/terraform.tfstate"
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

# Get bootstrap outputs
data "terraform_remote_state" "bootstrap" {
  backend = "azurerm"
  config = {
    resource_group_name  = "weatherapi-demo-terraform-state-rg"
    storage_account_name = "weatherdemotf7314"
    container_name       = "tfstate"
    key                  = "bootstrap/terraform.tfstate"
  }
}

# Data sources
data "azurerm_client_config" "current" {}

# Use the resource group created by bootstrap
data "azurerm_resource_group" "main" {
  name = data.terraform_remote_state.bootstrap.outputs.dev_resource_group_name
}

# Use the shared Key Vault from bootstrap
data "azurerm_key_vault" "shared" {
  name                = data.terraform_remote_state.bootstrap.outputs.key_vault_name
  resource_group_name = data.terraform_remote_state.bootstrap.outputs.app_resource_group_name
}

locals {
  environment   = "dev"
  workload_name = "weatherapi"
  location      = data.terraform_remote_state.bootstrap.outputs.location
  
  common_tags = merge(
    data.terraform_remote_state.bootstrap.outputs.common_tags,
    {
      Environment = local.environment
    }
  )
}

# Simple App Service Plan
resource "azurerm_service_plan" "main" {
  name                = "${local.environment}-${local.workload_name}-plan"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = local.location
  os_type             = "Linux"
  sku_name           = "B1"
  
  tags = local.common_tags
}

# Simple App Service
resource "azurerm_linux_web_app" "main" {
  name                = "${local.environment}-${local.workload_name}-app"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = local.location
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    always_on = false
    
    application_stack {
      dotnet_version = "8.0"
    }
  }

  app_settings = {
    "ENVIRONMENT_NAME" = local.environment
    "KeyVault__VaultUri" = data.azurerm_key_vault.shared.vault_uri
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# Grant App Service access to Key Vault
resource "azurerm_key_vault_access_policy" "app_service" {
  key_vault_id = data.azurerm_key_vault.shared.id
  tenant_id    = azurerm_linux_web_app.main.identity[0].tenant_id
  object_id    = azurerm_linux_web_app.main.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}
