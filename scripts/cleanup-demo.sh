#!/bin/bash
set -e

echo "🧹 WeatherAPI Demo Cleanup"
echo "=========================="

DEMO_PREFIX="weatherapi-demo"
SUBSCRIPTION_ID="b902128f-2e17-43c6-8ba5-49bf19e3f82b"  # Will be updated by setup script
FALLBACK_SUBSCRIPTION_ID="b902128f-2e17-43c6-8ba5-49bf19e3f82b"

# Try to read storage account from summary if it exists
if [ -f "setup-summary.txt" ]; then
    STORAGE_ACCOUNT_NAME=$(grep "Storage Account:" setup-summary.txt | cut -d' ' -f3)
    ACTUAL_SUBSCRIPTION_ID=$(grep "Subscription ID:" setup-summary.txt | cut -d' ' -f3)
    if [ ! -z "$ACTUAL_SUBSCRIPTION_ID" ]; then
        SUBSCRIPTION_ID="$ACTUAL_SUBSCRIPTION_ID"
    fi
    echo "📋 Found setup summary, using stored configuration"
fi

echo "🔍 Using subscription: ${SUBSCRIPTION_ID}"

# Set subscription
if ! az account set --subscription "${SUBSCRIPTION_ID}" 2>/dev/null; then
    echo "⚠️  Trying fallback subscription..."
    az account set --subscription "${FALLBACK_SUBSCRIPTION_ID}"
    SUBSCRIPTION_ID="${FALLBACK_SUBSCRIPTION_ID}"
fi

# Clean up via Terraform first (graceful)
echo "🏗️  Running Terraform destroy for graceful cleanup..."

if [ -d "terraform/environments/dev" ]; then
    echo "Destroying dev environment..."
    cd terraform/environments/dev
    if [ -f "terraform.tfstate" ] || [ -f ".terraform/terraform.tfstate" ]; then
        terraform init -input=false || echo "Dev init failed"
        terraform destroy -auto-approve || echo "Dev destroy failed, continuing..."
    fi
    cd ../../..
fi

if [ -d "terraform/environments/bootstrap" ]; then
    echo "Destroying bootstrap environment..."  
    cd terraform/environments/bootstrap
    if [ -f "terraform.tfstate" ] || [ -f ".terraform/terraform.tfstate" ]; then
        terraform init -input=false || echo "Bootstrap init failed"
        terraform destroy -auto-approve || echo "Bootstrap destroy failed, continuing..."
    fi
    cd ../../..
fi

# Force delete any remaining resource groups
echo "🗑️  Force deleting any remaining resource groups..."
for rg in $(az group list --query "[?contains(name, '${DEMO_PREFIX}')].name" -o tsv); do
    echo "Deleting resource group: $rg"
    az group delete --name "$rg" --yes --no-wait
done

# Delete service principal
echo "🔐 Deleting service principal..."
az ad sp delete --id "http://${DEMO_PREFIX}-github-actions-sp" || echo "Service principal not found"

# Clean up GitHub secrets if gh CLI is available and authenticated
echo "🔒 Cleaning up GitHub secrets..."
if command -v gh &> /dev/null && gh auth status &> /dev/null 2>&1; then
    echo "Removing GitHub secrets..."
    gh secret delete AZURE_CLIENT_ID --confirm || echo "Secret AZURE_CLIENT_ID not found"
    gh secret delete AZURE_CLIENT_SECRET --confirm || echo "Secret AZURE_CLIENT_SECRET not found"
    gh secret delete AZURE_SUBSCRIPTION_ID --confirm || echo "Secret AZURE_SUBSCRIPTION_ID not found"
    gh secret delete AZURE_TENANT_ID --confirm || echo "Secret AZURE_TENANT_ID not found"
    gh secret delete TERRAFORM_STORAGE_ACCOUNT --confirm || echo "Secret TERRAFORM_STORAGE_ACCOUNT not found"
    gh secret delete TERRAFORM_CONTAINER_NAME --confirm || echo "Secret TERRAFORM_CONTAINER_NAME not found"
    gh secret delete TERRAFORM_RESOURCE_GROUP --confirm || echo "Secret TERRAFORM_RESOURCE_GROUP not found"
    echo "✅ GitHub secrets cleaned up"
else
    echo "⚠️  GitHub CLI not available or not authenticated - skipping secret cleanup"
    echo "💡 Manually delete secrets in GitHub repository settings if needed"
fi

# Clean up local files
echo "🗂️  Cleaning up local files..."
rm -f service-principal-credentials.json
rm -f setup-summary.txt
rm -f terraform-backend-update.txt

# Clean up Terraform state and cache files
find . -name "terraform.tfstate*" -delete 2>/dev/null || true
find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true

echo ""
echo "✅ Cleanup complete!"
echo "🌐 Check Azure portal to confirm resource deletion: https://portal.azure.com"
echo "📱 Check GitHub repository settings to confirm secrets are removed"
echo ""
echo "💡 If any resources remain:"
echo "   - Check Azure portal for remaining resource groups"
echo "   - Manually delete any stuck resources"
echo "   - Check GitHub repository secrets in Settings > Secrets and variables > Actions" 