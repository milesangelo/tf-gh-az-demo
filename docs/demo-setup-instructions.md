# WeatherAPI Demo Setup Instructions

This document provides step-by-step instructions for setting up the WeatherAPI demo environment.

## Prerequisites

Before running the setup, ensure you have:

- ✅ **Azure CLI** installed and logged in (`az login`)
- ✅ **GitHub CLI** installed and authenticated (`gh auth login`)
- ✅ **Terraform** installed (version >= 1.0)
- ✅ **jq** installed for JSON processing
- ✅ Access to Azure subscription (Kilometers or Subscription 1)
- ✅ Repository access with admin permissions for secrets management

## Quick Setup

### 1. Run the Automated Setup

```bash
# Make the script executable
chmod +x scripts/setup-demo.sh

# Run the setup
./scripts/setup-demo.sh
```

The script will:

- Test your Azure subscriptions and select the best one
- Create minimal bootstrap resources (storage for Terraform state)
- Create service principal with appropriate permissions
- Automatically configure all GitHub repository secrets
- Update Terraform configurations with actual values

### 2. Initialize and Deploy Bootstrap Infrastructure

```bash
# Navigate to bootstrap environment
cd terraform/environments/bootstrap

# Initialize Terraform (should work automatically after setup)
terraform init

# Review the bootstrap plan
terraform plan

# Apply the bootstrap infrastructure
terraform apply
```

### 3. Deploy Development Environment

```bash
# Navigate to dev environment
cd ../dev

# Initialize Terraform
terraform init

# Review the dev environment plan
terraform plan

# Apply the dev infrastructure
terraform apply
```

## What Gets Created

### Azure Resources

**Bootstrap Resources:**

- Resource groups for each environment (dev, staging, prod)
- Shared Key Vault for secrets management
- Terraform state storage (created by setup script)

**Development Environment:**

- Virtual Network with subnets
- App Service Plan and Web App
- Azure SQL Database
- Application Insights
- Log Analytics Workspace
- Network Security Groups
- Storage Account for diagnostics

### GitHub Configuration

**Repository Secrets:**

- `AZURE_CLIENT_ID` - Service principal client ID
- `AZURE_CLIENT_SECRET` - Service principal secret
- `AZURE_SUBSCRIPTION_ID` - Azure subscription ID
- `AZURE_TENANT_ID` - Azure tenant ID
- `TERRAFORM_STORAGE_ACCOUNT` - Terraform state storage
- `TERRAFORM_CONTAINER_NAME` - State container name
- `TERRAFORM_RESOURCE_GROUP` - State resource group

**GitHub Actions Workflows:**

- Bootstrap infrastructure deployment
- Dev environment deployment
- Automated Terraform planning on PRs

## Testing the Setup

### Verify Azure Resources

```bash
# Check resource groups
az group list --query "[?contains(name, 'weatherapi-demo')]" --output table

# Check Key Vault
az keyvault list --query "[?contains(name, 'weatherapi-demo')]" --output table

# Check App Service
az webapp list --query "[?contains(name, 'weatherapi')]" --output table
```

### Verify GitHub Integration

1. Push changes to trigger workflows
2. Check Actions tab for successful runs
3. Verify secrets in repository settings

### Test Application Deployment

```bash
# Build and test the .NET application
cd src/WeatherApi
dotnet restore
dotnet build
dotnet test

# The application will be deployed via GitHub Actions
```

## Troubleshooting

### Common Issues

**Issue: Storage account name conflicts**

- The setup script generates unique names, but if you get conflicts, re-run the setup

**Issue: Service principal permissions**

- Ensure the service principal has Contributor access to the subscription
- Check that User Access Administrator role is assigned for resource management

**Issue: Terraform backend initialization**

- Verify storage account exists and is accessible
- Check that the storage account name was properly replaced in Terraform files

**Issue: GitHub CLI authentication**

- Run `gh auth login` and follow the prompts
- Ensure you have repository admin access for secrets management

### Manual Cleanup

If the automated cleanup fails:

```bash
# Delete resource groups manually
az group delete --name "weatherapi-demo-terraform-state-rg" --yes
az group delete --name "weatherapi-demo-app-rg" --yes
az group delete --name "weatherapi-demo-dev-rg" --yes
az group delete --name "weatherapi-demo-staging-rg" --yes
az group delete --name "weatherapi-demo-prod-rg" --yes

# Delete service principal
az ad sp delete --id "http://weatherapi-demo-github-actions-sp"

# Remove GitHub secrets manually via repository settings
```

## Demo Cleanup

When you're finished with the demo:

```bash
# Run the automated cleanup
./scripts/cleanup-demo.sh
```

This will:

- Destroy all Terraform-managed resources
- Delete Azure resource groups
- Remove service principal
- Clean up GitHub secrets
- Remove local temporary files

## Next Steps

After successful setup:

1. **Customize the application** - Modify the WeatherAPI code as needed
2. **Add more environments** - Create staging/prod configurations
3. **Enhance security** - Add more restrictive network rules, enable advanced security features
4. **Monitor and optimize** - Use Application Insights and Log Analytics for monitoring

## Support

If you encounter issues:

1. Check the `setup-summary.txt` file created by the setup script
2. Review GitHub Actions logs for deployment issues
3. Check Azure portal for resource status
4. Ensure all prerequisites are installed and configured
