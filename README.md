# Azure Landing Zone Demo with Terraform and GitHub Actions

This project demonstrates a complete enterprise-grade deployment pipeline using Azure Landing Zones, Terraform for Infrastructure as Code, and GitHub Actions for CI/CD.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Azure Landing Zone                       │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   Management    │  │    Identity     │  │   Connectivity  │  │
│  │   Subscription  │  │   Subscription  │  │   Subscription  │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                     Workload Subscriptions                     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │       Dev       │  │     Staging     │  │   Production    │  │
│  │   Environment   │  │   Environment   │  │   Environment   │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### 🎯 **Automated Setup (Recommended)**

For the easiest setup experience, use our automated demo setup:

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run automated setup (handles Azure resources + GitHub secrets)
./scripts/setup-demo.sh

# Deploy bootstrap infrastructure
cd terraform/environments/bootstrap
terraform init && terraform apply

# Deploy dev environment
cd ../dev
terraform init && terraform apply

# When done with demo
./scripts/cleanup-demo.sh
```

📖 **See [Demo Setup Instructions](docs/demo-setup-instructions.md) for detailed guidance**

### Prerequisites

1. **Azure CLI** - [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. **GitHub CLI** - [Install GitHub CLI](https://cli.github.com/)
3. **Terraform** - [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
4. **jq** - [Install jq](https://jqlang.github.io/jq/)
5. **.NET 8 SDK** - [Install .NET](https://dotnet.microsoft.com/download)

### 📖 Manual Setup (Alternative)

If you prefer manual setup or want to understand the process:

#### 1. Clone Repository

```bash
git clone https://github.com/your-org/azure-landing-zone-demo.git
cd azure-landing-zone-demo
```

#### 2. Setup Azure Authentication

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "your-subscription-id"

# Create service principal for Terraform
az ad sp create-for-rbac \
  --name "terraform-sp" \
  --role Contributor \
  --scopes /subscriptions/your-subscription-id \
  --sdk-auth
```

#### 3. Setup Terraform Backend

```bash
# Create resource group for Terraform state
az group create --name terraform-state-rg --location "East US 2"

# Create storage account for Terraform state
az storage account create \
  --name terraformstatestg$(openssl rand -hex 3) \
  --resource-group terraform-state-rg \
  --location "East US 2" \
  --sku Standard_LRS

# Create container for state files
az storage container create \
  --name tfstate \
  --account-name terraformstatestg123456
```

#### 4. Configure GitHub Secrets

Add these secrets to your GitHub repository:

- `AZURE_CLIENT_ID` - Service Principal Client ID
- `AZURE_CLIENT_SECRET` - Service Principal Client Secret
- `AZURE_SUBSCRIPTION_ID` - Your Azure subscription ID
- `AZURE_TENANT_ID` - Your Azure tenant ID

## 📁 Project Structure

```
azure-landing-zone-demo/
├── .github/
│   └── workflows/                  # GitHub Actions workflows
│       ├── terraform-bootstrap.yml # Bootstrap infrastructure deployment
│       └── terraform-dev.yml      # Dev environment deployment
├── scripts/
│   ├── setup-demo.sh              # 🎯 Automated demo setup
│   ├── cleanup-demo.sh            # 🧹 Complete cleanup script
│   └── make-executable.sh         # Helper script
├── terraform/
│   ├── modules/                    # Reusable Terraform modules
│   │   ├── landing-zone/           # Core landing zone infrastructure
│   │   ├── app-service/            # App Service configuration
│   │   └── database/               # Azure SQL Database setup
│   └── environments/               # Environment-specific configurations
│       ├── bootstrap/              # 🏗️ Bootstrap infrastructure
│       ├── dev/                    # Development environment
│       ├── staging/                # Staging environment
│       └── prod/                   # Production environment
├── src/
│   └── WeatherApi/                 # .NET 8 Web API application
│       ├── Controllers/
│       ├── Models/
│       ├── Services/
│       └── Data/
├── docs/
│   └── demo-setup-instructions.md # 📖 Detailed setup guide
└── README.md
```

## 🔧 Local Development

### Run the API Locally

```bash
cd src/WeatherApi
dotnet restore
dotnet run
```

The API will be available at `https://localhost:7001`

### Test Endpoints

```bash
# Get all weather data
curl https://localhost:7001/api/weather

# Get weather for specific city
curl https://localhost:7001/api/weather/Chicago

# Health check
curl https://localhost:7001/health
```

## 🌩️ Infrastructure Components

### Landing Zone Module

Creates the foundational infrastructure:

- **Virtual Network** with hub-spoke topology
- **Subnets** for applications and databases
- **Network Security Groups** with appropriate rules
- **Key Vault** for secrets management
- **Application Insights** for monitoring
- **Log Analytics Workspace** for centralized logging
- **Storage Account** for diagnostics and state

### App Service Module

Deploys the web application infrastructure:

- **App Service Plan** with appropriate SKU
- **Linux Web App** with .NET 8 runtime
- **VNet Integration** for secure networking
- **Auto-scaling** configuration (optional)
- **Deployment Slots** for blue-green deployments
- **Application Settings** with Key Vault references

### Database Module

Provisions Azure SQL Database:

- **SQL Server** with Azure AD authentication
- **SQL Database** with appropriate sizing
- **Firewall Rules** and VNet integration
- **Advanced Data Security** with threat detection
- **Automated Backups** with retention policies
- **Audit Logging** to storage account

## 🔄 CI/CD Pipeline

### Terraform Plan (Pull Requests)

Triggered on PRs affecting Terraform code:

1. Validates Terraform syntax
2. Runs `terraform plan`
3. Posts plan output as PR comment
4. Blocks merge on validation errors

### Terraform Apply (Main Branch)

Triggered on merges to main:

1. Initializes Terraform backend
2. Runs `terraform plan`
3. Applies infrastructure changes
4. Outputs deployment information

### Application Deployment

Triggered on application code changes:

1. **Build** - Compiles .NET application
2. **Test** - Runs unit tests
3. **Deploy** - Deploys to staging slot
4. **Smoke Test** - Validates deployment
5. **Swap Slots** - Promotes to production (manual approval)

## 🔒 Security Features

### Network Security

- Private subnets for databases
- Network Security Groups with minimal required access
- VNet integration for App Service
- Private endpoints for Azure services

### Identity & Access

- Azure AD authentication for SQL Server
- Managed Identity for App Service
- Key Vault for secrets management
- Role-based access control (RBAC)

### Monitoring & Compliance

- Application Insights for performance monitoring
- Log Analytics for centralized logging
- Azure Security Center integration
- Automated vulnerability assessments

## 📊 Monitoring & Observability

### Application Insights

- Real-time performance monitoring
- Custom telemetry and metrics
- Distributed tracing
- Availability tests

### Log Analytics

- Centralized log collection
- Custom queries and alerts
- Integration with Azure Monitor
- Long-term log retention

### Health Checks

- Built-in health endpoints
- Database connectivity checks
- Automated monitoring alerts

## 🌍 Environment Management

### Development Environment

- Basic SKUs for cost optimization
- Relaxed security for debugging
- Automatic database seeding
- Extended logging

### Staging Environment

- Production-like configuration
- Blue-green deployment slots
- Performance testing capabilities
- Security scanning

### Production Environment

- High-availability configuration
- Zone redundancy
- Enhanced monitoring
- Strict security policies

## 🛠️ Demo Walkthrough

### 1. Infrastructure Overview (5 minutes)

Show the Azure portal with deployed resources:

- Resource groups organization
- Networking topology
- Security configurations

### 2. Terraform Code Review (10 minutes)

Walk through the Terraform modules:

- Landing zone foundation
- App Service configuration
- Database setup
- Environment differences

### 3. GitHub Actions Pipeline (15 minutes)

Demonstrate the CI/CD process:

- Make a code change
- Show PR workflow with Terraform plan
- Merge and watch deployment
- Show application running

### 4. Monitoring & Management (10 minutes)

Show operational capabilities:

- Application Insights dashboards
- Log Analytics queries
- Cost management
- Security compliance

### 5. Scaling & Extensions (5 minutes)

Discuss how to extend the pattern:

- Adding new environments
- Scaling to multiple applications
- Cross-region deployment

## 🔗 Key Benefits Demonstrated

### Developer Experience

- **Self-Service Infrastructure** - Teams can provision standardized environments
- **Consistent Deployments** - Same process across all environments
- **Fast Feedback** - Automated testing and validation
- **Easy Rollbacks** - Blue-green deployments with quick rollback

### Operations Excellence

- **Infrastructure as Code** - Version controlled, peer reviewed
- **Automated Compliance** - Built-in security and governance
- **Centralized Monitoring** - Single pane of glass for observability
- **Cost Optimization** - Right-sized resources with auto-scaling

### Security & Governance

- **Defense in Depth** - Multiple layers of security controls
- **Least Privilege** - Minimal required permissions
- **Audit Trail** - Complete deployment and access history
- **Compliance** - Built-in policies and standards

## 📚 Additional Resources

- [Azure Landing Zones](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitHub Actions for Azure](https://docs.github.com/en/actions/deployment/deploying-to-your-cloud-provider/deploying-to-azure)
- [.NET on Azure](https://docs.microsoft.com/en-us/dotnet/azure/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Note**: This is a demonstration project. For production use, additional security hardening, monitoring, and governance controls should be implemented based on your organization's requirements.
