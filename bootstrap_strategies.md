# Infrastructure Bootstrap Strategies

## The Bootstrap Problem

When Terraform manages GitHub secrets for its own authentication, you create a circular dependency:
- Terraform needs credentials to run
- Terraform manages those same credentials
- If credentials break, how do you fix them?

## Approach 1: Manual Bootstrap (Current Demo)

### Architecture
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Platform      │───▶│  GitHub Secrets  │───▶│   Terraform     │
│   Admin         │    │  (Manual Setup)  │    │   Execution     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │   Azure Service  │    │ Infrastructure  │
                       │   Principal      │    │   Deployment    │
                       └──────────────────┘    └─────────────────┘
```

### Implementation
```bash
# One-time manual setup per repository
az ad sp create-for-rbac --name "repo-terraform-sp" \
  --role Contributor \
  --scopes /subscriptions/your-subscription-id

# Add to GitHub secrets manually or via CLI
gh secret set AZURE_CLIENT_ID --body "$CLIENT_ID"
gh secret set AZURE_CLIENT_SECRET --body "$CLIENT_SECRET"
gh secret set AZURE_SUBSCRIPTION_ID --body "$SUBSCRIPTION_ID"
gh secret set AZURE_TENANT_ID --body "$TENANT_ID"
```

### Pros
- ✅ Clear security boundaries
- ✅ No circular dependencies
- ✅ Easy to audit and troubleshoot
- ✅ Follows principle of least privilege
- ✅ Simple credential rotation

### Cons
- ❌ Manual setup required per repo
- ❌ Onboarding friction
- ❌ Not fully "infrastructure as code"

---

## Approach 2: Self-Bootstrapping Pipeline

### Architecture
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Bootstrap     │───▶│  Initial Service │───▶│   Terraform     │
│   Service       │    │   Principal      │    │   Bootstrap     │
│   Principal     │    │                  │    │   Module        │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │   GitHub App     │    │  Workload       │
                       │   + Secrets      │    │  Infrastructure │
                       └──────────────────┘    └─────────────────┘
```

### Implementation Structure
```
terraform/
├── bootstrap/                  # Self-bootstrapping module
│   ├── main.tf                # GitHub App + Service Principal creation
│   ├── github-secrets.tf      # Manages GitHub repository secrets
│   └── outputs.tf             # Outputs for workload modules
├── modules/
│   └── landing-zone/          # Your existing modules
└── environments/
    ├── bootstrap/             # Bootstrap environment
    └── dev/                   # Workload environments
```

---

## Approach 3: Hybrid - Platform Bootstrap (Recommended)

### Architecture
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Platform      │───▶│   Bootstrap      │───▶│    GitHub       │
│   Team          │    │   Terraform      │    │    App/Org      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │   Team Repos     │    │   Workload      │
                       │   Auto-Created   │    │   Infrastructure│
                       └──────────────────┘    └─────────────────┘
```

### Benefits
- ✅ Automated repo vending
- ✅ Centralized credential management
- ✅ Clear security boundaries
- ✅ Scales across teams
- ✅ Platform team controls bootstrap

---

## Demo Implementation: Bootstrap Module

```hcl
# terraform/bootstrap/main.tf
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

# Create dedicated service principal for this repository
resource "azurerm_ad_application" "terraform_app" {
  display_name = "${var.repository_name}-terraform"
  owners       = [data.azurerm_client_config.current.object_id]
}

resource "azurerm_ad_service_principal" "terraform_sp" {
  application_id = azurerm_ad_application.terraform_app.application_id
  owners         = [data.azurerm_client_config.current.object_id]
}

resource "azurerm_ad_service_principal_password" "terraform_sp_password" {
  service_principal_id = azurerm_ad_service_principal.terraform_sp.object_id
  end_date_relative    = "8760h" # 1 year
}

# Assign appropriate roles
resource "azurerm_role_assignment" "terraform_contributor" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azurerm_ad_service_principal.terraform_sp.object_id
}

# Create GitHub repository secrets
resource "github_actions_secret" "azure_client_id" {
  repository      = var.repository_name
  secret_name     = "AZURE_CLIENT_ID"
  plaintext_value = azurerm_ad_service_principal.terraform_sp.application_id
}

resource "github_actions_secret" "azure_client_secret" {
  repository      = var.repository_name
  secret_name     = "AZURE_CLIENT_SECRET"
  plaintext_value = azurerm_ad_service_principal_password.terraform_sp_password.value
}

resource "github_actions_secret" "azure_subscription_id" {
  repository      = var.repository_name
  secret_name     = "AZURE_SUBSCRIPTION_ID"
  plaintext_value = var.subscription_id
}

resource "github_actions_secret" "azure_tenant_id" {
  repository      = var.repository_name
  secret_name     = "AZURE_TENANT_ID"
  plaintext_value = data.azurerm_client_config.current.tenant_id
}
```

## Recommended Demo Approach

### For Your 1-Hour Demo: Stick with Manual Bootstrap

**Why:**
- Focuses on core concepts (Landing Zones, App Deployment)
- Avoids complexity that distracts from main points
- Easier to troubleshoot during live demo
- Most teams start here anyway

### Show Bootstrap as Advanced Topic

**Demo Flow:**
1. **Main Demo** (45 min) - Use manual secrets, focus on landing zones
2. **Advanced Section** (15 min) - Show bootstrap module as "next level"
3. **Discussion** - Explain when teams graduate to self-bootstrapping

### Code Structure for Demo

```
terraform/
├── bootstrap/                 # Show this as "advanced pattern"
│   ├── main.tf               # GitHub integration
│   └── repository-setup.tf   # Automated repo configuration
├── modules/                   # Your existing modules (main demo)
└── environments/             # Manual secrets (main demo)
```

## Security Considerations

### Manual Bootstrap
```bash
# Principle of least privilege
az role assignment create \
  --assignee $SP_ID \
  --role "Landing Zone Contributor" \  # Custom role, not full Contributor
  --scope "/subscriptions/$SUB_ID/resourceGroups/allowed-*"
```

### Self-Bootstrap
```hcl
# Break-glass access for platform team
resource "azurerm_role_assignment" "platform_emergency" {
  scope                = azurerm_ad_service_principal.terraform_sp.object_id
  role_definition_name = "User Access Administrator"
  principal_id         = var.platform_team_group_id
  
  # Only for credential recovery
  condition = "emergency_access_approved"
}
```

## When to Use Each Approach

### Manual Bootstrap ✅
- **Small teams** (< 10 developers)
- **Few repositories** (< 5 repos)
- **Security-first environments**
- **Demo/learning scenarios**
- **Getting started with IaC**

### Self-Bootstrap ✅
- **Large organizations** (100+ repositories)
- **Platform teams** managing multiple teams
- **Repo vending/templating systems**
- **Mature DevOps practices**
- **Compliance automation required**

## Demo Talking Points

### Main Demo (Manual)
*"We start with manual setup because it's the most secure and easiest to understand. Most teams begin here."*

### Advanced Section (Self-Bootstrap)
*"As you scale to hundreds of repositories and teams, you'd move to automated bootstrap. This is what platform teams implement for enterprise-wide standardization."*

### Questions to Address
- "How do you handle the initial credentials for self-bootstrap?" → Platform team with elevated permissions
- "What if the bootstrap breaks?" → Break-glass procedures and backup service principals
- "How do you rotate credentials?" → Automated rotation with Azure Key Vault

The manual approach is perfect for your demo - it's more secure, easier to understand, and shows the foundations before getting into advanced automation patterns.