# Azure Landing Zone Demo with Terraform and GitHub Actions

## Overview
This demo showcases a modern cloud deployment pipeline using:
- **Terraform** for Infrastructure as Code (IaC)
- **Azure Landing Zone** architecture patterns
- **Repo Vending Control Plane** pattern for standardized deployments
- **GitHub Actions** for CI/CD pipeline
- **.NET Web API** as the sample application

## Demo Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Developer     │───▶│  GitHub Actions  │───▶│  Azure Landing  │
│   Commits Code  │    │   CI/CD Pipeline │    │     Zone        │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │   Terraform      │    │  App Service    │
                       │   Plan/Apply     │    │  + Database     │
                       └──────────────────┘    └─────────────────┘
```

## Key Concepts Demonstrated

### 1. Landing Zone Pattern
- **Management Groups**: Organized hierarchy for governance
- **Subscriptions**: Isolated environments (dev, staging, prod)
- **Resource Groups**: Logical grouping of related resources
- **Networking**: Hub-spoke topology with shared services

### 2. Repo Vending Control Plane
- **Template Repository**: Standardized project structure
- **Automated Provisioning**: Self-service infrastructure creation
- **Governance**: Built-in policies and compliance
- **Standardization**: Consistent deployment patterns

### 3. Infrastructure as Code
- **Terraform Modules**: Reusable infrastructure components
- **State Management**: Remote state with Azure Storage
- **Environment Promotion**: Dev → Staging → Production
- **Drift Detection**: Continuous compliance monitoring
- **Deterministic Naming**: Predictable resource names without random suffixes for reliable state management

## Project Structure

```
azure-landing-zone-demo/
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml
│       ├── terraform-apply.yml
│       └── app-deploy.yml
├── terraform/
│   ├── modules/
│   │   ├── landing-zone/
│   │   ├── app-service/
│   │   └── database/
│   ├── environments/
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   └── main.tf
├── src/
│   └── WeatherApi/
│       ├── Controllers/
│       ├── Models/
│       ├── Program.cs
│       └── WeatherApi.csproj
├── docs/
│   ├── architecture.md
│   ├── deployment-guide.md
│   └── troubleshooting.md
└── README.md
```

## Demo Flow (45-50 minutes + Q&A)

### Phase 1: Landing Zone Setup (15 minutes)
1. **Explain Landing Zone Concept** (5 min)
   - Show management group hierarchy
   - Discuss subscription organization
   - Explain hub-spoke networking

2. **Terraform Landing Zone Module** (10 min)
   - Walk through landing-zone module
   - Show how it creates foundation resources
   - Demonstrate policy assignments

### Phase 2: Application Infrastructure (15 minutes)
1. **App Service Module** (8 min)
   - Show app-service Terraform module
   - Explain scaling and security configurations
   - Demonstrate environment-specific variables

2. **Database Module** (7 min)
   - Walk through Azure SQL configuration
   - Show backup and security settings
   - Explain connection string management

### Phase 3: CI/CD Pipeline (15 minutes)
1. **GitHub Actions Workflow** (8 min)
   - Show terraform-plan workflow
   - Explain approval process for apply
   - Demonstrate app deployment pipeline

2. **Live Deployment** (7 min)
   - Make a code change
   - Trigger pipeline
   - Watch infrastructure and app deploy

### Phase 4: Monitoring & Governance (5 minutes)
1. **Show Azure Portal** (3 min)
   - Resource organization
   - Cost management
   - Compliance dashboard

2. **Demonstrate Self-Service** (2 min)
   - Show how new teams can use the pattern
   - Explain repo vending process

## Prerequisites for Demo

### Azure Setup
```bash
# Install Azure CLI
az login
az account set --subscription "your-subscription-id"

# Create service principal for GitHub Actions
az ad sp create-for-rbac --name "github-actions-sp" \
  --role Contributor \
  --scopes /subscriptions/your-subscription-id
```

### GitHub Setup
1. Fork the demo repository
2. Add these secrets to your GitHub repository:
   - `AZURE_CLIENT_ID`
   - `AZURE_CLIENT_SECRET`
   - `AZURE_SUBSCRIPTION_ID`
   - `AZURE_TENANT_ID`

### Local Development
```bash
# Install required tools
# Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# .NET SDK
wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update && sudo apt-get install -y dotnet-sdk-8.0
```

## Key Demo Points to Emphasize

### 1. Governance and Compliance
- Show how policies are automatically applied
- Demonstrate cost controls and resource limits
- Explain audit trails and compliance reporting

### 2. Developer Experience
- Self-service infrastructure provisioning
- Standardized environments across teams
- Automatic security and compliance

### 3. Operational Excellence
- Infrastructure as Code benefits
- Automated testing and validation
- Environment promotion strategies

### 4. Cost Optimization
- Resource tagging and cost allocation
- Automatic scaling policies
- Development environment shutdown

## Common Questions & Answers

**Q: How do we handle secrets management?**
A: We use Azure Key Vault integrated with GitHub Actions and App Service. Secrets are never stored in code.

**Q: What about multi-region deployments?**
A: The landing zone pattern supports multiple regions through the hub-spoke model with traffic manager.

**Q: How do we handle database migrations?**
A: The pipeline includes Entity Framework migrations as part of the deployment process.

**Q: Can teams customize their infrastructure?**
A: Yes, through approved Terraform modules and variable overrides while maintaining governance.

**Q: What about disaster recovery?**
A: Built into the landing zone with automated backups, geo-replication, and recovery procedures.

**Q: How do you avoid naming conflicts without random suffixes?**
A: We use deterministic naming conventions based on environment, workload, and region. For globally unique resources like storage accounts, we use a consistent pattern like `{environment}{workload}st01`. Teams can increment the numeric suffix if needed, or add region codes for multi-region deployments.

**Q: What if we need to recreate resources?**
A: Deterministic naming ensures resources can be recreated with the same names, preventing state drift. For emergency situations, we can use `terraform import` to bring existing resources back into state management.

## Next Steps After Demo

1. **Pilot Program**: Start with one team/application
2. **Training**: Terraform and Azure fundamentals
3. **Governance**: Establish policies and approval processes
4. **Monitoring**: Set up alerting and dashboards
5. **Scaling**: Expand to additional teams and applications

## Resources for Further Learning

- [Azure Landing Zones Documentation](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitHub Actions for Azure](https://docs.github.com/en/actions/deployment/deploying-to-your-cloud-provider/deploying-to-azure)
- [Azure Well-Architected Framework](https://docs.microsoft.com/en-us/azure/architecture/framework/)

---

*This demo project serves as a foundation for implementing enterprise-grade cloud infrastructure with modern DevOps practices.*