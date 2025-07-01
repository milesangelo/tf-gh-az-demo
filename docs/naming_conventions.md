# Azure Resource Naming Conventions

## Overview

This document defines the naming conventions used in the demo to ensure predictable, manageable resource names without relying on random suffixes that can cause Terraform state drift issues.

## Naming Pattern

```
{environment}-{workload}-{resource-type}[-{instance}]
```

## Resource Type Abbreviations

| Resource | Abbreviation | Example |
|----------|-------------|---------|
| Resource Group | rg | `dev-weatherapi-rg` |
| Virtual Network | vnet | `dev-hub-vnet` |
| Subnet | subnet | `app-subnet`, `db-subnet` |
| Network Security Group | nsg | `dev-app-nsg` |
| App Service Plan | plan | `dev-weatherapi-plan` |
| App Service | app | `dev-weatherapi-app` |
| SQL Server | sql | `dev-weatherapi-sql` |
| SQL Database | db | `dev-weatherapi-db` |
| Key Vault | kv | `dev-weatherapi-kv` |
| Storage Account | st | `devweatherapist01` |
| Log Analytics | logs | `dev-weatherapi-logs` |
| Application Insights | ai | `dev-weatherapi-ai` |

## Special Considerations

### Globally Unique Resources

Some Azure resources require globally unique names. For these, we use a compressed format:

#### Storage Accounts
- **Pattern**: `{env}{workload}st{instance}`
- **Example**: `devweatherapist01`
- **Rules**: 
  - Max 24 characters, lowercase only
  - No hyphens allowed
  - Globally unique across all Azure

#### Key Vaults
- **Pattern**: `{environment}-{workload}-kv`
- **Example**: `dev-weatherapi-kv`
- **Rules**:
  - Max 24 characters
  - Globally unique across all Azure
  - Must start with letter

### SQL Servers
- **Pattern**: `{environment}-{workload}-sql`
- **Example**: `dev-weatherapi-sql`
- **Rules**:
  - Globally unique across all Azure
  - Must be 1-63 characters
  - Only lowercase letters, numbers, and hyphens

## Environment-Specific Examples

### Development Environment
```hcl
# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "dev-weatherapi-rg"
  location = "East US 2"
}

# App Service
resource "azurerm_linux_web_app" "app" {
  name = "dev-weatherapi-app"
  # ...
}

# SQL Server
resource "azurerm_mssql_server" "sql" {
  name = "dev-weatherapi-sql"
  # ...
}

# Storage Account (compressed format)
resource "azurerm_storage_account" "storage" {
  name = "devweatherapist01"
  # ...
}
```

### Production Environment
```hcl
# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "prod-weatherapi-rg"
  location = "East US 2"
}

# App Service
resource "azurerm_linux_web_app" "app" {
  name = "prod-weatherapi-app"
  # ...
}

# SQL Server
resource "azurerm_mssql_server" "sql" {
  name = "prod-weatherapi-sql"
  # ...
}

# Storage Account (compressed format)
resource "azurerm_storage_account" "storage" {
  name = "prodweatherapist01"
  # ...
}
```

## Multi-Region Deployments

For multi-region deployments, add region abbreviation:

| Region | Abbreviation |
|--------|-------------|
| East US 2 | eus2 |
| West US 2 | wus2 |
| Central US | cus |
| North Central US | ncus |
| UK South | uks |
| West Europe | weu |

### Examples
```hcl
# Primary region (East US 2)
resource "azurerm_linux_web_app" "app_primary" {
  name = "prod-weatherapi-app-eus2"
}

# Secondary region (West US 2)
resource "azurerm_linux_web_app" "app_secondary" {
  name = "prod-weatherapi-app-wus2"
}
```

## Multiple Instances

When you need multiple instances of the same resource type:

```hcl
# Multiple storage accounts
resource "azurerm_storage_account" "storage_primary" {
  name = "prodweatherapist01"
}

resource "azurerm_storage_account" "storage_backup" {
  name = "prodweatherapist02"
}

# Multiple app services
resource "azurerm_linux_web_app" "app_api" {
  name = "prod-weatherapi-app"
}

resource "azurerm_linux_web_app" "app_worker" {
  name = "prod-weatherworker-app"
}
```

## Validation Rules

### Terraform Variables
Add validation to ensure naming conventions are followed:

```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "workload_name" {
  description = "Workload name"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]+$", var.workload_name))
    error_message = "Workload name must contain only lowercase letters and numbers."
  }
}
```

## Benefits

### Predictable Names
- No random suffixes that can cause state drift
- Easy to identify resources and their purpose
- Consistent across all environments

### Easier Management
- Simple to script and automate
- Clear resource relationships
- Simplified troubleshooting

### Team Adoption
- Easy to understand and follow
- Self-documenting resource purpose
- Reduces naming conflicts

## Conflict Resolution

If naming conflicts occur:

1. **Storage Accounts**: Increment numeric suffix (`st01` → `st02`)
2. **Key Vaults**: Add region code (`-kv` → `-kv-eus2`)
3. **SQL Servers**: Add region or instance identifier
4. **App Services**: Add specific function identifier

## Implementation in Terraform

### Local Values Pattern
```hcl
locals {
  environment   = "dev"
  workload_name = "weatherapi"
  location_abbr = "eus2"
  
  # Base naming convention
  naming_prefix = "${local.environment}-${local.workload_name}"
  
  # Resource names
  resource_group_name = "${local.naming_prefix}-rg"
  app_service_name    = "${local.naming_prefix}-app"
  sql_server_name     = "${local.naming_prefix}-sql"
  key_vault_name      = "${local.naming_prefix}-kv"
  storage_name        = "${local.environment}${local.workload_name}st01"
}
```

This approach ensures consistent, predictable naming while avoiding the state drift issues that come with random suffixes.