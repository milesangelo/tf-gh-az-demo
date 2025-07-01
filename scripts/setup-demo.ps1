# PowerShell version for Windows - avoids Git Bash path issues
Write-Host "🚀 Starting WeatherAPI Demo Azure Setup" -ForegroundColor Green
Write-Host "========================================"

# Set variables
$DEMO_PREFIX = "weatherapi-demo"
$LOCATION = "East US 2"
$SUBSCRIPTION_ID = "b902128f-2e17-43c6-8ba5-49bf19e3f82b"
$SUBSCRIPTION_NAME = "Subscription 1"

Write-Host "🎯 Using FIXED subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)" -ForegroundColor Yellow

# Set the subscription
try {
    az account set --subscription $SUBSCRIPTION_ID
    Write-Host "✅ Subscription set successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to set subscription: $SUBSCRIPTION_ID" -ForegroundColor Red
    Write-Host "💡 Make sure you have access to Subscription 1 and are logged in to Azure CLI" -ForegroundColor Yellow
    exit 1
}

# Clean up existing service principal
$SP_NAME = "$DEMO_PREFIX-github-actions-sp"
Write-Host "🧹 Cleaning up any existing service principal..." -ForegroundColor Yellow
az ad sp delete --id "http://$SP_NAME" 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Cleaned up existing service principal" -ForegroundColor Green
} else {
    Write-Host "ℹ️  No existing service principal found" -ForegroundColor Cyan
}

# Generate unique storage account name
$timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds().ToString().Substring(6)
$STORAGE_ACCOUNT_NAME = "weatherdemotf$timestamp"

Write-Host "🏗️  Creating bootstrap resources..." -ForegroundColor Yellow

# Bootstrap resource group
$rgResult = az group create --name "$DEMO_PREFIX-terraform-state-rg" --location $LOCATION --tags Project="WeatherAPI-Demo" Owner="$env:USERNAME" Purpose="TerraformBootstrap" --output none
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Created resource group: $DEMO_PREFIX-terraform-state-rg" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to create resource group" -ForegroundColor Red
    exit 1
}

# Bootstrap storage account
az storage account create --name $STORAGE_ACCOUNT_NAME --resource-group "$DEMO_PREFIX-terraform-state-rg" --location $LOCATION --sku Standard_LRS --kind StorageV2 --allow-blob-public-access false --tags Project="WeatherAPI-Demo" Owner="$env:USERNAME" Purpose="TerraformState" --output none

az storage container create --name "tfstate" --account-name $STORAGE_ACCOUNT_NAME --auth-mode login --output none

Write-Host "✅ Created storage account: $STORAGE_ACCOUNT_NAME" -ForegroundColor Green

# Create service principal - PROPER PATH FORMAT
Write-Host "🔐 Creating service principal..." -ForegroundColor Yellow

$spResult = az ad sp create-for-rbac --name $SP_NAME --role "Contributor" --scopes "/subscriptions/$SUBSCRIPTION_ID" --output json | ConvertFrom-Json

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to create service principal" -ForegroundColor Red
    exit 1
}

# Wait for propagation
Write-Host "⏳ Waiting for service principal propagation..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Get service principal object ID
$SP_OBJECT_ID = az ad sp show --id $spResult.appId --query id -o tsv

# Additional role assignments with proper path format
Write-Host "🔐 Adding additional permissions..." -ForegroundColor Yellow

az role assignment create --assignee $SP_OBJECT_ID --role "Storage Blob Data Contributor" --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$DEMO_PREFIX-terraform-state-rg" --output none

az role assignment create --assignee $SP_OBJECT_ID --role "User Access Administrator" --scope "/subscriptions/$SUBSCRIPTION_ID" --output none

az role assignment create --assignee $SP_OBJECT_ID --role "Key Vault Administrator" --scope "/subscriptions/$SUBSCRIPTION_ID" --output none

Write-Host "✅ Service Principal created with all permissions" -ForegroundColor Green

# Check GitHub CLI
Write-Host "🔍 Checking GitHub CLI..." -ForegroundColor Yellow
if (!(Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "❌ GitHub CLI not found. Please install: https://cli.github.com/" -ForegroundColor Red
    exit 1
}

$ghAuthResult = gh auth status 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "🔐 Please authenticate with GitHub CLI:" -ForegroundColor Yellow
    gh auth login
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ GitHub authentication failed" -ForegroundColor Red
        exit 1
    }
}

# Set GitHub repository secrets
Write-Host "🔐 Setting GitHub repository secrets..." -ForegroundColor Yellow

gh secret set AZURE_CLIENT_ID --body $spResult.appId
gh secret set AZURE_CLIENT_SECRET --body $spResult.password
gh secret set AZURE_SUBSCRIPTION_ID --body $SUBSCRIPTION_ID
gh secret set AZURE_TENANT_ID --body $spResult.tenant

# Terraform backend secrets
gh secret set TERRAFORM_STORAGE_ACCOUNT --body $STORAGE_ACCOUNT_NAME
gh secret set TERRAFORM_CONTAINER_NAME --body "tfstate"
gh secret set TERRAFORM_RESOURCE_GROUP --body "$DEMO_PREFIX-terraform-state-rg"

Write-Host "✅ GitHub secrets configured automatically!" -ForegroundColor Green

# Update Terraform configurations
Write-Host "🏗️  Updating Terraform backend configurations..." -ForegroundColor Yellow

if (Test-Path "terraform/environments/bootstrap/main.tf") {
    (Get-Content "terraform/environments/bootstrap/main.tf") -replace "REPLACE_WITH_ACTUAL_STORAGE_ACCOUNT", $STORAGE_ACCOUNT_NAME | Set-Content "terraform/environments/bootstrap/main.tf"
    Write-Host "✅ Updated bootstrap Terraform configuration" -ForegroundColor Green
}

if (Test-Path "terraform/environments/dev/main.tf") {
    (Get-Content "terraform/environments/dev/main.tf") -replace "REPLACE_WITH_ACTUAL_STORAGE_ACCOUNT", $STORAGE_ACCOUNT_NAME | Set-Content "terraform/environments/dev/main.tf"
    Write-Host "✅ Updated dev Terraform configuration" -ForegroundColor Green
}

# Create summary
$summaryContent = @"
WeatherAPI Demo Setup Summary
============================

Subscription Used: $SUBSCRIPTION_NAME
Subscription ID: $SUBSCRIPTION_ID
Storage Account: $STORAGE_ACCOUNT_NAME
Location: $LOCATION

Resource Groups Created:
- $DEMO_PREFIX-terraform-state-rg (Terraform state storage)

Service Principal: $SP_NAME
Service Principal App ID: $($spResult.appId)

GitHub Secrets Set:
- AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_SUBSCRIPTION_ID, AZURE_TENANT_ID
- TERRAFORM_STORAGE_ACCOUNT, TERRAFORM_CONTAINER_NAME, TERRAFORM_RESOURCE_GROUP

Next Steps:
1. Run Terraform bootstrap: cd terraform/environments/bootstrap && terraform init && terraform plan && terraform apply
2. Run dev environment: cd terraform/environments/dev && terraform init && terraform plan && terraform apply
"@

$summaryContent | Out-File -FilePath "setup-summary.txt" -Encoding UTF8

Write-Host "✅ Setup summary saved to setup-summary.txt" -ForegroundColor Green
Write-Host ""
Write-Host "🎉 Demo setup completed successfully!" -ForegroundColor Green
Write-Host "📋 See setup-summary.txt for next steps" -ForegroundColor Cyan