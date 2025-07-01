
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Landing Zone Resource Group
resource "azurerm_resource_group" "landing_zone" {
  name     = "${var.environment}-${var.workload_name}-rg"
  location = var.location

  tags = merge(var.common_tags, {
    Environment = var.environment
    Workload    = var.workload_name
    Purpose     = "Landing Zone"
  })
}

# Virtual Network (Hub-Spoke Pattern)
resource "azurerm_virtual_network" "hub_vnet" {
  name                = "${var.environment}-hub-vnet"
  address_space       = [var.hub_address_space]
  location            = azurerm_resource_group.landing_zone.location
  resource_group_name = azurerm_resource_group.landing_zone.name

  tags = var.common_tags
}

# Subnets
resource "azurerm_subnet" "app_subnet" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.landing_zone.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = [var.app_subnet_prefix]

  service_endpoints = ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.KeyVault"]
}

resource "azurerm_subnet" "db_subnet" {
  name                 = "db-subnet"
  resource_group_name  = azurerm_resource_group.landing_zone.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = [var.db_subnet_prefix]
}

# Network Security Groups
resource "azurerm_network_security_group" "app_nsg" {
  name                = "${var.environment}-app-nsg"
  location            = azurerm_resource_group.landing_zone.location
  resource_group_name = azurerm_resource_group.landing_zone.name

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.common_tags
}

resource "azurerm_subnet_network_security_group_association" "app_nsg_association" {
  subnet_id                 = azurerm_subnet.app_subnet.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

# Key Vault for secrets management
resource "azurerm_key_vault" "landing_zone_kv" {
  name                = "${var.environment}-${var.workload_name}-kv"
  location            = azurerm_resource_group.landing_zone.location
  resource_group_name = azurerm_resource_group.landing_zone.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  enabled_for_deployment          = true

  # Network ACLs
  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = [azurerm_subnet.app_subnet.id]
  }

  tags = var.common_tags
}

# Access policy for the current deployment identity
resource "azurerm_key_vault_access_policy" "deployment_policy" {
  key_vault_id = azurerm_key_vault.landing_zone_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
  ]

  key_permissions = [
    "Get", "List", "Create", "Delete", "Recover", "Backup", "Restore"
  ]
}

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "landing_zone_logs" {
  name                = "${var.environment}-${var.workload_name}-logs"
  location            = azurerm_resource_group.landing_zone.location
  resource_group_name = azurerm_resource_group.landing_zone.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = var.common_tags
}

# Application Insights
resource "azurerm_application_insights" "landing_zone_ai" {
  name                = "${var.environment}-${var.workload_name}-ai"
  location            = azurerm_resource_group.landing_zone.location
  resource_group_name = azurerm_resource_group.landing_zone.name
  workspace_id        = azurerm_log_analytics_workspace.landing_zone_logs.id
  application_type    = "web"

  tags = var.common_tags
}

# Storage Account for Terraform state and diagnostics
resource "azurerm_storage_account" "landing_zone_storage" {
  name                     = "${var.environment}${var.workload_name}st01"
  resource_group_name      = azurerm_resource_group.landing_zone.name
  location                 = azurerm_resource_group.landing_zone.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.app_subnet.id]
    bypass                     = ["AzureServices"]
  }

  tags = var.common_tags
}

data "azurerm_client_config" "current" {}

# Store connection strings in Key Vault
resource "azurerm_key_vault_secret" "storage_connection_string" {
  name         = "storage-connection-string"
  value        = azurerm_storage_account.landing_zone_storage.primary_connection_string
  key_vault_id = azurerm_key_vault.landing_zone_kv.id

  depends_on = [azurerm_key_vault_access_policy.deployment_policy]
}

resource "azurerm_key_vault_secret" "app_insights_connection_string" {
  name         = "applicationinsights-connection-string"
  value        = azurerm_application_insights.landing_zone_ai.connection_string
  key_vault_id = azurerm_key_vault.landing_zone_kv.id

  depends_on = [azurerm_key_vault_access_policy.deployment_policy]
}