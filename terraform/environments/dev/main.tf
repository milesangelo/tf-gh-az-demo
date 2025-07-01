
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
    storage_account_name = "REPLACE_WITH_ACTUAL_STORAGE_ACCOUNT"
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
    storage_account_name = "REPLACE_WITH_ACTUAL_STORAGE_ACCOUNT"
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

# Landing Zone Module
module "landing_zone" {
  source = "../../modules/landing-zone"
  
  environment         = local.environment
  workload_name      = local.workload_name
  location           = local.location
  resource_group_name = data.azurerm_resource_group.main.name
  hub_address_space  = "10.0.0.0/16"
  app_subnet_prefix  = "10.0.1.0/24"
  db_subnet_prefix   = "10.0.2.0/24"
  log_retention_days = 30
  common_tags        = local.common_tags
  
  # Use shared Key Vault from bootstrap
  use_existing_key_vault = true
  existing_key_vault_id  = data.azurerm_key_vault.shared.id
}

# Database Module
module "database" {
  source = "../../modules/database"
  
  environment                             = local.environment
  database_name                          = local.workload_name
  resource_group_name                    = data.azurerm_resource_group.main.name
  location                               = local.location
  sql_admin_username                     = "sqladmin"
  azuread_admin_login                    = "Platform Team"
  azuread_admin_object_id               = data.azurerm_client_config.current.object_id
  database_sku                          = "Basic"
  max_size_gb                           = 2
  app_subnet_id                         = module.landing_zone.app_subnet_id
  key_vault_id                          = data.azurerm_key_vault.shared.id
  log_analytics_workspace_id            = module.landing_zone.log_analytics_workspace_id
  storage_account_name                  = module.landing_zone.storage_account_name
  storage_account_primary_blob_endpoint = "https://${module.landing_zone.storage_account_name}.blob.core.windows.net/"
  storage_account_primary_access_key    = "placeholder" # This should be retrieved from state or data source
  backup_retention_days                 = 7
  audit_retention_days                  = 30
  security_alert_emails                 = ["mvendetti@company.com"]
  enable_vulnerability_assessment       = false # Disabled for dev environment
  common_tags                           = local.common_tags
  
  depends_on = [module.landing_zone]
}

# App Service Module
module "app_service" {
  source = "../../modules/app-service"
  
  environment                            = local.environment
  app_name                              = local.workload_name
  resource_group_name                   = data.azurerm_resource_group.main.name
  location                              = local.location
  sku_name                              = "B1"
  app_subnet_id                         = module.landing_zone.app_subnet_id
  key_vault_id                          = data.azurerm_key_vault.shared.id
  key_vault_name                        = data.azurerm_key_vault.shared.name
  application_insights_key              = module.landing_zone.application_insights_key
  application_insights_connection_string = module.landing_zone.application_insights_connection_string
  enable_autoscaling                    = false
  enable_staging_slot                   = true
  log_retention_days                    = 7
  
  additional_app_settings = {
    "ENVIRONMENT_NAME" = local.environment
    "FEATURE_FLAGS__NEW_WEATHER_API" = "true"
    "BOOTSTRAP_RESOURCE_GROUP" = data.terraform_remote_state.bootstrap.outputs.app_resource_group_name
  }
  
  common_tags = local.common_tags
  
  depends_on = [module.database]
}

# Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = data.azurerm_resource_group.main.name
}

output "app_service_url" {
  description = "URL of the App Service"
  value       = module.app_service.app_service_default_hostname
  sensitive   = false
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = data.azurerm_key_vault.shared.name
}

output "environment" {
  description = "Environment name"
  value       = local.environment
}
