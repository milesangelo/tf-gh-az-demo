#!/bin/bash
set -e

echo "🚀 Starting WeatherAPI Demo Azure Setup"
echo "========================================"

# Set variables
export DEMO_PREFIX="weatherapi-demo"
export LOCATION="East US 2"
export KILOMETERS_SUBSCRIPTION_ID="b902128f-2e17-43c6-8ba5-49bf19e3f82b"
export FALLBACK_SUBSCRIPTION_ID="b902128f-2e17-43c6-8ba5-49bf19e3f82b"

# Test and set subscription
echo "🔍 Testing Kilometers Subscription..."
if az account set --subscription "${KILOMETERS_SUBSCRIPTION_ID}" 2>/dev/null; then
    export SUBSCRIPTION_ID="${KILOMETERS_SUBSCRIPTION_ID}"
    export SUBSCRIPTION_NAME="Kilometers"
    echo "✅ Using Kilometers Subscription"
else
    echo "⚠️  Falling back to Subscription 1"
    export SUBSCRIPTION_ID="${FALLBACK_SUBSCRIPTION_ID}"
    export SUBSCRIPTION_NAME="Subscription1"
    az account set --subscription "${SUBSCRIPTION_ID}"
fi

echo "📋 Using Subscription: ${SUBSCRIPTION_NAME} (${SUBSCRIPTION_ID})"

# Generate unique storage account name
export STORAGE_ACCOUNT_NAME="weatherdemotf$(date +%s | tail -c 6)"

echo "🏗️  Creating bootstrap resources..."

# Bootstrap resource group for Terraform state only
az group create \
  --name "${DEMO_PREFIX}-terraform-state-rg" \
  --location "${LOCATION}" \
  --tags Project="WeatherAPI-Demo" Owner="mvendetti" Purpose="TerraformBootstrap" \
  --output none

echo "✅ Created resource group: ${DEMO_PREFIX}-terraform-state-rg"

# Bootstrap storage account for Terraform state
az storage account create \
  --name "${STORAGE_ACCOUNT_NAME}" \
  --resource-group "${DEMO_PREFIX}-terraform-state-rg" \
  --location "${LOCATION}" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --allow-blob-public-access false \
  --tags Project="WeatherAPI-Demo" Owner="mvendetti" Purpose="TerraformState" \
  --output none

az storage container create \
  --name "tfstate" \
  --account-name "${STORAGE_ACCOUNT_NAME}" \
  --auth-mode login \
  --output none

echo "✅ Created storage account: ${STORAGE_ACCOUNT_NAME}"

# Create service principal with subscription-level access (Terraform needs this initially)
export SP_NAME="${DEMO_PREFIX}-github-actions-sp"

echo "🔐 Creating service principal..."

az ad sp create-for-rbac \
  --name "${SP_NAME}" \
  --role "Contributor" \
  --scopes "/subscriptions/${SUBSCRIPTION_ID}" \
  --output json > service-principal-credentials.json

# Grant additional permissions needed for Terraform
export SP_APP_ID=$(jq -r '.appId' service-principal-credentials.json)
export SP_OBJECT_ID=$(az ad sp show --id "${SP_APP_ID}" --query id -o tsv)

# Storage permissions for state management
az role assignment create \
  --assignee "${SP_OBJECT_ID}" \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${DEMO_PREFIX}-terraform-state-rg" \
  --output none

# Additional roles needed for Terraform to create Azure resources
az role assignment create \
  --assignee "${SP_OBJECT_ID}" \
  --role "User Access Administrator" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}" \
  --output none

echo "✅ Service Principal created for Terraform"

# Extract credentials for GitHub secrets
export AZURE_CLIENT_ID=$(jq -r '.appId' service-principal-credentials.json)
export AZURE_CLIENT_SECRET=$(jq -r '.password' service-principal-credentials.json)
export AZURE_TENANT_ID=$(jq -r '.tenant' service-principal-credentials.json)

# Check GitHub CLI
echo "🔍 Checking GitHub CLI..."
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI not found. Please install: https://cli.github.com/"
    echo "💡 After installing, run: gh auth login"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo "🔐 Please authenticate with GitHub CLI:"
    gh auth login
    if ! gh auth status &> /dev/null; then
        echo "❌ GitHub authentication failed"
        exit 1
    fi
fi

# Set GitHub repository secrets
echo "🔐 Setting GitHub repository secrets..."

gh secret set AZURE_CLIENT_ID --body "${AZURE_CLIENT_ID}"
gh secret set AZURE_CLIENT_SECRET --body "${AZURE_CLIENT_SECRET}"
gh secret set AZURE_SUBSCRIPTION_ID --body "${SUBSCRIPTION_ID}"
gh secret set AZURE_TENANT_ID --body "${AZURE_TENANT_ID}"

# Terraform backend secrets
gh secret set TERRAFORM_STORAGE_ACCOUNT --body "${STORAGE_ACCOUNT_NAME}"
gh secret set TERRAFORM_CONTAINER_NAME --body "tfstate"
gh secret set TERRAFORM_RESOURCE_GROUP --body "${DEMO_PREFIX}-terraform-state-rg"

echo "✅ GitHub secrets configured automatically!"

# Update Terraform backend configurations
echo "🏗️  Updating Terraform backend configurations..."

# Update bootstrap configuration
if [ -f "terraform/environments/bootstrap/main.tf" ]; then
    sed -i "s/REPLACE_WITH_ACTUAL_STORAGE_ACCOUNT/${STORAGE_ACCOUNT_NAME}/g" terraform/environments/bootstrap/main.tf
    echo "✅ Updated bootstrap Terraform configuration"
fi

# Update dev configuration  
if [ -f "terraform/environments/dev/main.tf" ]; then
    sed -i "s/REPLACE_WITH_ACTUAL_STORAGE_ACCOUNT/${STORAGE_ACCOUNT_NAME}/g" terraform/environments/dev/main.tf
    echo "✅ Updated dev Terraform configuration"
fi

# Create summary file
cat > setup-summary.txt << EOF
WeatherAPI Demo Setup Summary
============================

Subscription Used: ${SUBSCRIPTION_NAME}
Subscription ID: ${SUBSCRIPTION_ID}
Storage Account: ${STORAGE_ACCOUNT_NAME}
Location: ${LOCATION}

Resource Groups Created:
- ${DEMO_PREFIX}-terraform-state-rg (Terraform state storage)

Service Principal: ${SP_NAME}
Service Principal App ID: ${AZURE_CLIENT_ID}

GitHub Secrets Set:
- AZURE_CLIENT_ID
- AZURE_CLIENT_SECRET  
- AZURE_SUBSCRIPTION_ID
- AZURE_TENANT_ID
- TERRAFORM_STORAGE_ACCOUNT
- TERRAFORM_CONTAINER_NAME
- TERRAFORM_RESOURCE_GROUP

Next Steps:
1. Run Terraform bootstrap: cd terraform/environments/bootstrap && terraform init && terraform plan && terraform apply
2. Run dev environment: cd terraform/environments/dev && terraform init && terraform plan && terraform apply
3. Push changes to trigger GitHub Actions
4. When done, run: ./scripts/cleanup-demo.sh

Files to commit:
- terraform/environments/bootstrap/main.tf
- terraform/environments/dev/main.tf (updated)
- .github/workflows/terraform-bootstrap.yml
- scripts/ (this directory)
EOF

echo "✅ Setup summary saved to setup-summary.txt"

# Clean up sensitive file
rm -f service-principal-credentials.json

echo ""
echo "🎉 Demo setup completed successfully!"
echo "📋 See setup-summary.txt for next steps"
echo "🧹 When done with demo, run: ./scripts/cleanup-demo.sh" 