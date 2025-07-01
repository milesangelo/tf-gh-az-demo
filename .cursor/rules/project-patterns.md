# WeatherAPI Demo - Project Intelligence

## Key Implementation Patterns

### Terraform Bootstrap Pattern

- **Bootstrap-first approach**: Always create foundational resources (resource groups, Key Vault, shared services) in a separate Terraform configuration before application-specific environments
- **Remote state consumption**: Dev/staging/prod environments consume bootstrap outputs via `terraform_remote_state` data sources
- **Shared vs isolated resources**: Shared Key Vault for demo simplicity, but separate resource groups for environment isolation

### Automated Secrets Management

- **GitHub CLI integration**: Use `gh` CLI to automatically set repository secrets rather than manual configuration
- **Service principal automation**: Create Azure service principals with minimal required permissions via script
- **Template replacement**: Use placeholder values in Terraform files, replace with actual values during setup script execution

### Subscription Flexibility Pattern

```bash
# Always test primary subscription first, graceful fallback
if az account set --subscription "${PRIMARY_SUB}" 2>/dev/null; then
    echo "Using primary subscription..."
else
    echo "Falling back to secondary subscription..."
    az account set --subscription "${FALLBACK_SUB}"
fi
```

### Script Lifecycle Management

- **Setup script**: Complete Azure + GitHub automation in single script
- **Cleanup script**: Graceful Terraform destroy → force delete resource groups → service principal cleanup → GitHub secrets cleanup
- **Executable scripts**: Always use `chmod +x` and provide helper scripts for permissions

## User Preferences & Workflow

### Documentation Approach

- **Automated setup prominence**: Always feature the automated setup instructions prominently in README
- **Manual alternatives**: Provide manual setup instructions as backup option
- **Troubleshooting sections**: Include common issues and solutions
- **Step-by-step guides**: Clear numbered steps with expected time estimates

### Terraform Organization

- **Environment directories**: Separate directories for bootstrap, dev, staging, prod
- **Module references**: Reference modules even if they don't exist yet to show intended architecture
- **Variable files**: Use `.tfvars` files for environment-specific configuration
- **State management**: Always use remote state with environment-specific state files

### Security Patterns

- **Minimal permissions**: Service principals with only required roles
- **Environment isolation**: Separate resource groups per environment
- **Secrets externalization**: No secrets in code, all in Key Vault or GitHub secrets
- **Network security**: NSGs and VNet integration even for demo environments

## Demo-Specific Considerations

### Cost Optimization for Demos

- **Basic SKUs**: Use B1 App Service, Basic SQL Database for cost efficiency
- **Short retention**: 7-day backup retention, 7-day soft delete for Key Vault
- **Resource cleanup**: Easy teardown more important than production resilience

### Subscription Handling

- **Kilometers Subscription**: Primary subscription (cead65d9-c5f9-4662-ad69-1013b8762473)
- **Subscription 1**: Fallback option (b902128f-2e17-43c6-8ba5-49bf19e3f82b)
- **Automatic detection**: Script should test and handle both seamlessly

### Resource Naming Convention

```bash
RESOURCE_PREFIX="weatherapi-demo"
STORAGE_ACCOUNT_NAME="${RESOURCE_PREFIX}tfstate$(date +%s)"  # Unique suffix
SERVICE_PRINCIPAL_NAME="${RESOURCE_PREFIX}-github-actions-sp"
RESOURCE_GROUPS:
  - ${RESOURCE_PREFIX}-terraform-state-rg     # Bootstrap state storage
  - ${RESOURCE_PREFIX}-app-rg                 # Shared application resources
  - ${RESOURCE_PREFIX}-dev-rg                 # Development environment
  - ${RESOURCE_PREFIX}-staging-rg             # Staging environment (future)
  - ${RESOURCE_PREFIX}-prod-rg                # Production environment (future)
```

## GitHub Actions Patterns

### Workflow Structure

- **Bootstrap workflow**: Manual trigger, separate from application deployments
- **Environment workflows**: PR planning, main branch deployment
- **Working directory**: Always specify working directory for Terraform commands
- **Artifact handling**: Upload plan files for review, download for apply

### Secret Management

```bash
# Required GitHub Secrets (set via script)
AZURE_CLIENT_ID              # Service Principal Application ID
AZURE_CLIENT_SECRET          # Service Principal Secret
AZURE_SUBSCRIPTION_ID        # Target Azure Subscription
AZURE_TENANT_ID              # Azure AD Tenant ID
TERRAFORM_STORAGE_ACCOUNT    # State storage account name
TERRAFORM_CONTAINER_NAME     # State container name (tfstate)
TERRAFORM_RESOURCE_GROUP     # State resource group name
```

## Memory Bank Integration

### Core Files Hierarchy

1. **projectbrief.md** → Foundation, drives all other files
2. **productContext.md** → Business context and user experience
3. **systemPatterns.md** → Architecture and technical decisions
4. **techContext.md** → Technology stack and constraints
5. **progress.md** → Current status and what's working
6. **activeContext.md** → Current focus and recent changes

### Update Triggers

- Major architectural changes
- New patterns discovered
- User feedback integration
- Project milestone completion
- When explicitly requested with "update memory bank"

## Critical Success Factors

### Demo Readiness

- **5-minute setup**: Complete Azure and GitHub configuration
- **Repeatable process**: Same results every time
- **Easy cleanup**: Single command removes all resources
- **Cost control**: Predictable costs with automatic cleanup

### Enterprise Patterns

- **Infrastructure as Code**: Everything defined in Terraform
- **Security by Design**: Minimal permissions, proper isolation
- **CI/CD Integration**: Automated deployment pipelines
- **Documentation**: Self-service capability for team members

## Known Constraints & Solutions

### GitHub CLI Dependency

- **Requirement**: GitHub CLI must be installed and authenticated
- **Solution**: Provide manual alternative in documentation
- **Detection**: Script should check for `gh` command availability

### Service Principal Permissions

- **Requirement**: Subscription-level permissions for Terraform
- **Solution**: Minimal role set (Contributor + Storage Blob Data Contributor + User Access Administrator + Key Vault Administrator)
- **Scope**: Subscription level for resource creation flexibility

### Module Dependencies

- **Current**: Terraform configurations reference modules that may need updates
- **Solution**: Document expected module interface, implement/update as needed
- **Pattern**: Use `use_existing_key_vault` parameter for shared Key Vault integration

This project demonstrates enterprise-grade Azure deployment patterns with complete automation, making it an excellent reference for future Azure Landing Zone implementations.
