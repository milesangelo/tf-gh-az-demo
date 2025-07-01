#!/bin/bash
set -e

echo "🧹 WeatherAPI Demo Cleanup"
echo "=========================="

DEMO_PREFIX="weatherapi-demo"

# Function to detect subscription from summary or prompt user
detect_subscription() {
    # Try to read from setup summary first
    if [ -f "setup-summary.txt" ]; then
        SUMMARY_SUB=$(grep "Subscription ID:" setup-summary.txt | cut -d' ' -f3 2>/dev/null || echo "")
        if [ ! -z "$SUMMARY_SUB" ]; then
            SUMMARY_NAME=$(grep "Subscription Used:" setup-summary.txt | cut -d' ' -f3- 2>/dev/null || echo "Saved Subscription")
            echo "📋 Found setup summary with subscription: $SUMMARY_NAME ($SUMMARY_SUB)"
            
            read -p "Use this subscription for cleanup? (y/n) [y]: " -r REPLY
            REPLY=${REPLY:-y}
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                export SUBSCRIPTION_ID="$SUMMARY_SUB"
                return 0
            fi
        fi
    fi
    
    # Get current subscription if one is already set
    CURRENT_SUB=$(az account show --query id -o tsv 2>/dev/null || echo "")
    
    if [ ! -z "$CURRENT_SUB" ]; then
        CURRENT_NAME=$(az account show --query name -o tsv 2>/dev/null || echo "Current Subscription")
        echo "📋 Found active subscription: $CURRENT_NAME ($CURRENT_SUB)"
        
        read -p "Use this subscription for cleanup? (y/n) [y]: " -r REPLY
        REPLY=${REPLY:-y}
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            export SUBSCRIPTION_ID="$CURRENT_SUB"
            return 0
        fi
    fi
    
    # List available subscriptions
    echo "Available subscriptions:"
    az account list --query "[].{Name:name, SubscriptionId:id, State:state}" -o table
    
    echo ""
    read -p "Enter subscription ID to use for cleanup: " -r SUBSCRIPTION_INPUT
    
    if [ -z "$SUBSCRIPTION_INPUT" ]; then
        echo "❌ No subscription ID provided"
        exit 1
    fi
    
    export SUBSCRIPTION_ID="$SUBSCRIPTION_INPUT"
}

# Detect and set subscription
detect_subscription

echo "🔍 Using subscription: ${SUBSCRIPTION_ID}"

# Set subscription
if ! az account set --subscription "${SUBSCRIPTION_ID}" 2>/dev/null; then
    echo "❌ Failed to set subscription: ${SUBSCRIPTION_ID}"
    exit 1
fi

# Try to read storage account from summary if it exists
if [ -f "setup-summary.txt" ]; then
    STORAGE_ACCOUNT_NAME=$(grep "Storage Account:" setup-summary.txt | cut -d' ' -f3 2>/dev/null || echo "")
    echo "📋 Found storage account from summary: ${STORAGE_ACCOUNT_NAME}"
fi

# Clean up via Terraform first (graceful)
echo "🏗️  Running Terraform destroy for graceful cleanup..."

if [ -d "terraform/environments/dev" ]; then
    echo "Destroying dev environment..."
    cd terraform/environments/dev
    if [ -f "terraform.tfstate" ] || [ -f ".terraform/terraform.tfstate" ] || [ -d ".terraform" ]; then
        terraform init -input=false || echo "Dev init failed"
        terraform destroy -auto-approve || echo "Dev destroy failed, continuing..."
    fi
    cd ../../..
fi

if [ -d "terraform/environments/bootstrap" ]; then
    echo "Destroying bootstrap environment..."  
    cd terraform/environments/bootstrap
    if [ -f "terraform.tfstate" ] || [ -f ".terraform/terraform.tfstate" ] || [ -d ".terraform" ]; then
        terraform init -input=false || echo "Bootstrap init failed"
        terraform destroy -auto-approve || echo "Bootstrap destroy failed, continuing..."
    fi
    cd ../../..
fi

# Force delete any remaining resource groups
echo "🗑️  Force deleting any remaining resource groups..."
for rg in $(az group list --query "[?contains(name, '${DEMO_PREFIX}')].name" -o tsv 2>/dev/null || echo ""); do
    if [ ! -z "$rg" ]; then
        echo "Deleting resource group: $rg"
        az group delete --name "$rg" --yes --no-wait
    fi
done

# Delete service principal
echo "🔐 Deleting service principal..."
az ad sp delete --id "http://${DEMO_PREFIX}-github-actions-sp" 2>/dev/null || echo "Service principal not found"

# Clean up GitHub secrets if gh CLI is available and authenticated
echo "🔒 Cleaning up GitHub secrets..."
if command -v gh &> /dev/null && gh auth status &> /dev/null 2>&1; then
    echo "Removing GitHub secrets..."
    gh secret delete AZURE_CLIENT_ID --confirm 2>/dev/null || echo "Secret AZURE_CLIENT_ID not found"
    gh secret delete AZURE_CLIENT_SECRET --confirm 2>/dev/null || echo "Secret AZURE_CLIENT_SECRET not found"
    gh secret delete AZURE_SUBSCRIPTION_ID --confirm 2>/dev/null || echo "Secret AZURE_SUBSCRIPTION_ID not found"
    gh secret delete AZURE_TENANT_ID --confirm 2>/dev/null || echo "Secret AZURE_TENANT_ID not found"
    gh secret delete TERRAFORM_STORAGE_ACCOUNT --confirm 2>/dev/null || echo "Secret TERRAFORM_STORAGE_ACCOUNT not found"
    gh secret delete TERRAFORM_CONTAINER_NAME --confirm 2>/dev/null || echo "Secret TERRAFORM_CONTAINER_NAME not found"
    gh secret delete TERRAFORM_RESOURCE_GROUP --confirm 2>/dev/null || echo "Secret TERRAFORM_RESOURCE_GROUP not found"
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