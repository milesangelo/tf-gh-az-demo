# Technology Context - WeatherAPI Demo

## Technology Stack Overview

### Core Technologies

#### Infrastructure as Code

- **Terraform** (>= 1.0)
  - **Provider**: AzureRM (~> 3.0)
  - **Provider**: AzureAD (~> 2.0)
  - **Provider**: Random (~> 3.0)
  - **Backend**: Azure Storage (remote state)
  - **Usage**: All infrastructure provisioning and management

#### Cloud Platform

- **Microsoft Azure**
  - **Subscription**: Kilometers (primary) / Subscription 1 (fallback)
  - **Region**: East US 2
  - **Authentication**: Service Principal
  - **Services**: App Service, SQL Database, Key Vault, VNet, NSG, Application Insights

#### Application Platform

- **.NET 8**
  - **Framework**: ASP.NET Core Web API
  - **Runtime**: Linux containers
  - **Hosting**: Azure App Service (Linux)
  - **Dependencies**: Entity Framework Core, Application Insights SDK

#### CI/CD Platform

- **GitHub Actions**
  - **Runners**: ubuntu-latest
  - **Workflows**: terraform-bootstrap.yml, terraform-dev.yml
  - **Secrets**: Azure credentials, Terraform backend configuration
  - **Features**: Manual triggers, PR automation, artifact storage

### Development Tools

#### Command Line Tools

```bash
# Required Tools
az               # Azure CLI (latest)
gh               # GitHub CLI (latest)
terraform        # Terraform (>= 1.0)
jq               # JSON processor (latest)
dotnet           # .NET SDK 8.0

# Shell Requirements
bash             # Bash shell (Git Bash on Windows)
chmod            # File permissions (included in Git Bash)
sed              # Stream editor (included in Git Bash)
```

#### Local Development Environment

- **Operating System**: Windows 10/11 (with Git Bash)
- **IDE**: Visual Studio Code (recommended)
- **Extensions**: Azure, Terraform, GitHub Actions
- **Git**: Latest version with SSH/HTTPS authentication

### Azure Services Configuration

#### App Service

```hcl
# Configuration
sku_name                = "B1"           # Basic tier for demo
os_type                 = "Linux"
dotnet_version         = "8.0"
enable_staging_slot    = true           # Blue-green deployment
vnet_integration       = true           # Network security
```

#### Azure SQL Database

```hcl
# Configuration
sku_name               = "Basic"         # 5 DTU for demo
max_size_gb           = 2               # Minimal storage
backup_retention_days = 7               # Short retention for demo
azuread_authentication = true          # Modern authentication
```

#### Key Vault

```hcl
# Configuration
sku_name                     = "standard"
soft_delete_retention_days   = 7         # Demo cleanup friendly
purge_protection_enabled     = false     # Allow complete cleanup
enabled_for_deployment       = true      # App Service integration
```

#### Virtual Network

```hcl
# Address Space
hub_address_space    = "10.0.0.0/16"
app_subnet_prefix   = "10.0.1.0/24"     # Application subnet
db_subnet_prefix    = "10.0.2.0/24"     # Database subnet
```

### Dependencies and Versions

#### .NET Application Dependencies

```xml
<PackageReference Include="Microsoft.ApplicationInsights.AspNetCore" Version="2.21.0" />
<PackageReference Include="Microsoft.AspNetCore.OpenApi" Version="8.0.0" />
<PackageReference Include="Microsoft.EntityFrameworkCore.SqlServer" Version="8.0.0" />
<PackageReference Include="Microsoft.EntityFrameworkCore.Tools" Version="8.0.0" />
<PackageReference Include="Microsoft.Extensions.Diagnostics.HealthChecks.EntityFrameworkCore" Version="8.0.0" />
<PackageReference Include="Swashbuckle.AspNetCore" Version="6.5.0" />
<PackageReference Include="Swashbuckle.AspNetCore.Annotations" Version="6.5.0" />
<PackageReference Include="Azure.Extensions.AspNetCore.Configuration.Secrets" Version="1.3.0" />
<PackageReference Include="Azure.Identity" Version="1.10.4" />
```

#### Terraform Provider Versions

```hcl
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
}
```

#### GitHub Actions Versions

```yaml
# Action Versions
actions/checkout@v4                    # Source code checkout
hashicorp/setup-terraform@v3           # Terraform installation
azure/login@v1                        # Azure authentication
actions/github-script@v7               # GitHub API interaction
actions/upload-artifact@v4             # Artifact management
```

## Development Setup Requirements

### Prerequisites Installation

#### Windows Environment

```bash
# Install using package managers
winget install Microsoft.AzureCLI
winget install GitHub.CLI
winget install Hashicorp.Terraform
winget install jqlang.jq

# Or use Chocolatey
choco install azure-cli github-cli terraform jq

# .NET 8 SDK
winget install Microsoft.DotNet.SDK.8
```

#### Authentication Setup

```bash
# Azure CLI authentication
az login

# GitHub CLI authentication
gh auth login

# Verify authentication
az account show
gh auth status
```

### Local Development Workflow

#### Project Setup

```bash
# Clone repository
git clone https://github.com/milesangelo/tf-gh-az-demo.git
cd tf-gh-az-demo

# Make scripts executable
chmod +x scripts/*.sh

# Verify tool versions
az --version
gh --version
terraform version
jq --version
dotnet --version
```

#### Development Commands

```bash
# Application development
cd src/WeatherApi
dotnet restore
dotnet build
dotnet run

# Infrastructure development
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

## Technical Constraints

### Azure Limitations

- **Resource Naming**: Globally unique names required for storage accounts
- **Service Principal**: Subscription-level permissions needed for Terraform
- **Key Vault**: Soft delete enabled, affects cleanup timing
- **App Service**: Linux plan required for .NET 8 containers

### Terraform Constraints

- **State Management**: Remote state requires Azure Storage pre-creation
- **Provider Limitations**: Some Azure features not yet supported
- **Dependency Management**: Module dependencies must be carefully ordered

### GitHub Actions Constraints

- **Runner Limitations**: Ubuntu-only for Azure CLI compatibility
- **Secret Management**: Limited to repository-level secrets
- **Concurrent Runs**: Limited by GitHub Actions quotas

### Demo Environment Constraints

- **Cost Optimization**: Using minimal SKUs (B1, Basic, Standard)
- **Cleanup Requirements**: All resources must be easily removable
- **Isolation Requirements**: No impact on existing Azure resources

## Security Configuration

### Service Principal Permissions

```bash
# Required Roles
Contributor                    # Resource management
Storage Blob Data Contributor  # Terraform state access
User Access Administrator      # Role assignment management
Key Vault Administrator        # Secrets management
```

### Network Security

```hcl
# Network Security Groups
app_nsg_rules = [
  {
    name                     = "AllowHTTPS"
    priority                 = 100
    direction               = "Inbound"
    access                  = "Allow"
    protocol                = "Tcp"
    source_port_range       = "*"
    destination_port_range  = "443"
    source_address_prefix   = "*"
    destination_address_prefix = "*"
  }
]
```

### Secrets Management

```bash
# GitHub Repository Secrets
AZURE_CLIENT_ID              # Service Principal ID
AZURE_CLIENT_SECRET          # Service Principal Secret
AZURE_SUBSCRIPTION_ID        # Azure Subscription
AZURE_TENANT_ID              # Azure Tenant
TERRAFORM_STORAGE_ACCOUNT    # State Storage Account
TERRAFORM_CONTAINER_NAME     # State Container
TERRAFORM_RESOURCE_GROUP     # State Resource Group
```

## Performance Considerations

### Application Performance

- **App Service Plan**: B1 tier (1 vCPU, 1.75 GB RAM)
- **Database**: Basic tier (5 DTU)
- **Storage**: Standard LRS for cost optimization
- **CDN**: Not implemented (demo scope)

### Infrastructure Performance

- **Terraform Execution**: Parallel resource creation where possible
- **State Management**: Small state files for fast operations
- **Network Latency**: Single region deployment

### Scalability Limits

- **Demo Scope**: Not designed for production load
- **Manual Scaling**: No auto-scaling configured
- **Resource Limits**: Basic tier limitations apply

## Monitoring and Diagnostics

### Application Insights Configuration

```csharp
// Application monitoring
services.AddApplicationInsightsTelemetry();
services.AddHealthChecks()
    .AddEntityFrameworkCore<WeatherContext>();
```

### Log Analytics Integration

```hcl
# Diagnostic settings
log_analytics_workspace_id = module.landing_zone.log_analytics_workspace_id
diagnostic_logs = [
  "ApplicationGatewayAccessLog",
  "ApplicationGatewayPerformanceLog",
  "ApplicationGatewayFirewallLog"
]
```

## Future Technology Considerations

### Potential Enhancements

- **Container Registry**: Azure Container Registry for custom images
- **API Management**: Azure API Management for API gateway
- **Service Bus**: Message queuing for decoupled architecture
- **Cosmos DB**: NoSQL database alternatives
- **Front Door**: Global load balancing and CDN

### Technology Evolution

- **.NET Updates**: Migration path to future .NET versions
- **Terraform Updates**: Provider version management strategy
- **Azure Services**: New service adoption patterns
- **GitHub Actions**: Advanced workflow patterns
