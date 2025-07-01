# Complete Demo Build Guide - AI Assistant Prompts

## 🎯 Pre-Demo Checklist
**Use these prompts sequentially with your AI assistant to build the complete demo by tomorrow.**

---

## Phase 1: Project Foundation (30 minutes)

### Prompt 1.1: Create Project Structure
```
Create a complete folder structure for an Azure Landing Zone demo project. I need:

1. Root directory with README.md
2. Terraform modules directory structure for:
   - landing-zone module
   - app-service module  
   - database module
3. Terraform environments for dev, staging, prod
4. GitHub Actions workflows directory
5. .NET 8 Web API source code structure
6. Documentation folder

Show me the exact folder structure and create a .gitignore file for Terraform and .NET projects.
```

### Prompt 1.2: Initialize Git Repository
```
Help me initialize this as a Git repository with proper branch protection. I need:

1. Git initialization commands
2. Initial commit structure
3. Branch protection rules for main branch
4. GitHub repository creation commands using GitHub CLI
5. Basic contributing guidelines

Provide the exact commands I need to run.
```

---

## Phase 2: Terraform Infrastructure (45 minutes)

### Prompt 2.1: Landing Zone Module
```
Create a complete Terraform landing zone module for Azure with these requirements:

1. Virtual network with hub-spoke architecture
2. Subnets for applications and databases with proper CIDR ranges
3. Network Security Groups with appropriate rules
4. Azure Key Vault for secrets management
5. Log Analytics workspace and Application Insights
6. Storage account for diagnostics
7. Use deterministic naming (no random suffixes)
8. Include proper tagging strategy
9. All variables, outputs, and validation rules

Make it production-ready with security best practices.
```

### Prompt 2.2: App Service Module
```
Create a Terraform module for Azure App Service that includes:

1. Linux App Service Plan with appropriate SKU
2. Linux Web App configured for .NET 8
3. VNet integration with the landing zone subnet
4. Managed identity configuration
5. Application settings that reference Key Vault secrets
6. Auto-scaling configuration (optional)
7. Deployment slots for blue-green deployments
8. Health check endpoints
9. Connection to Application Insights
10. Proper security configurations

Include comprehensive variables and outputs.
```

### Prompt 2.3: Database Module
```
Create a Terraform module for Azure SQL Database with:

1. Azure SQL Server with Azure AD authentication
2. SQL Database with appropriate sizing options
3. Firewall rules and VNet integration
4. Advanced Data Security and threat detection
5. Automated backup configuration
6. Audit logging to storage account
7. Key Vault integration for connection strings
8. Diagnostic settings for monitoring
9. Long-term retention policies for production
10. Security best practices

Make it configurable for different environments (dev/staging/prod).
```

### Prompt 2.4: Environment Configuration
```
Create Terraform environment configurations for dev, staging, and prod environments:

1. Main.tf files that use the landing zone, app service, and database modules
2. Variables.tf with environment-specific defaults
3. Terraform.tfvars examples for each environment
4. Outputs.tf that expose important resource information
5. Backend configuration for remote state
6. Provider configuration with appropriate features
7. Local values for consistent naming

Show different configurations for each environment (different SKUs, features, etc.).
```

---

## Phase 3: .NET Application (30 minutes)

### Prompt 3.1: .NET Web API Application
```
Create a complete .NET 8 Web API application called WeatherApi with:

1. Controllers for weather data with CRUD operations
2. Entity Framework models and DbContext
3. Service layer with dependency injection
4. Application Insights integration
5. Health check endpoints
6. Swagger/OpenAPI documentation
7. Configuration for different environments
8. Docker support with proper Dockerfile
9. Connection string management with Key Vault
10. Proper error handling and logging

Make it ready for Azure App Service deployment.
```

### Prompt 3.2: Project Configuration Files
```
Create all the project configuration files for the .NET application:

1. .csproj file with all necessary NuGet packages
2. appsettings.json for each environment (Development, Staging, Production)
3. Program.cs with proper service configuration
4. Dockerfile optimized for production
5. .dockerignore file
6. Directory.Build.props for solution-wide settings
7. Database migration files (if using EF migrations)

Ensure everything works with Azure App Service and Application Insights.
```

---

## Phase 4: CI/CD Pipeline (45 minutes)

### Prompt 4.1: Terraform GitHub Actions
```
Create GitHub Actions workflows for Terraform:

1. terraform-plan.yml - Runs on pull requests to validate and plan
2. terraform-apply.yml - Runs on main branch merges with environment selection
3. Include proper Azure authentication using service principal
4. Add Terraform state management with Azure backend
5. Include security scanning and validation
6. Add pull request commenting with plan output
7. Support for multiple environments (dev, staging, prod)
8. Proper error handling and rollback capabilities

Make them production-ready with security best practices.
```

### Prompt 4.2: Application Deployment Pipeline
```
Create GitHub Actions workflows for .NET application deployment:

1. app-deploy.yml with build, test, and deploy stages
2. Support for deployment slots (staging/production)
3. Database migration handling
4. Smoke tests after deployment
5. Slot swapping for blue-green deployments
6. Environment-specific configurations
7. Artifact management and caching
8. Security scanning and code quality checks
9. Approval gates for production deployments

Include comprehensive error handling and monitoring.
```

### Prompt 4.3: Pipeline Security & Secrets
```
Help me configure GitHub repository security for the CI/CD pipeline:

1. List of required GitHub secrets and their purposes
2. Azure service principal creation commands
3. GitHub repository security settings
4. Branch protection rules configuration
5. Environment protection rules for staging/prod
6. Dependabot configuration for dependency updates
7. CodeQL security scanning setup
8. Required status checks configuration

Provide exact commands and settings I need to configure.
```

---

## Phase 5: Documentation & Demo Prep (30 minutes)

### Prompt 5.1: Complete Documentation
```
Create comprehensive documentation for the demo project:

1. Main README.md with architecture overview and quick start
2. Deployment guide with step-by-step instructions
3. Architecture documentation with diagrams
4. Troubleshooting guide for common issues
5. Demo script with timing and talking points
6. API documentation for the weather service
7. Infrastructure cost estimates for each environment
8. Security documentation and compliance notes

Make it suitable for both technical teams and management presentations.
```

### Prompt 5.2: Demo Preparation Scripts
```
Create helper scripts and tools for the demo:

1. Azure CLI script to set up initial resources (service principal, storage account)
2. Local development setup script
3. Environment validation script to check all components
4. Demo data seeding script for the database
5. Load testing script to show auto-scaling
6. Cleanup script to tear down demo resources
7. Cost monitoring queries for Azure
8. Health check script to verify all components

Include error handling and clear output messages.
```

---

## Phase 6: Testing & Validation (30 minutes)

### Prompt 6.1: Infrastructure Testing
```
Help me create tests and validation for the infrastructure:

1. Terraform validation commands for each module
2. terraform fmt and terraform validate scripts
3. Infrastructure testing with Terratest or similar
4. Azure Policy compliance checks
5. Security scanning with tools like tfsec or Checkov
6. Cost analysis and optimization recommendations
7. Performance testing scenarios
8. Disaster recovery testing procedures

Provide scripts I can run to validate everything works.
```

### Prompt 6.2: Application Testing
```
Create comprehensive tests for the .NET application:

1. Unit tests for services and controllers
2. Integration tests with in-memory database
3. Health check validation
4. API endpoint testing with sample requests
5. Performance testing scripts
6. Security testing (authentication, authorization)
7. Database migration testing
8. Docker container validation

Include test data and example requests I can use during the demo.
```

---

## Phase 7: Demo Execution (15 minutes)

### Prompt 7.1: Demo Script & Timing
```
Create a detailed demo script for a 1-hour presentation:

1. 5-minute introduction with architecture overview
2. 15-minute Terraform landing zone walkthrough
3. 15-minute CI/CD pipeline demonstration
4. 10-minute live application deployment
5. 10-minute monitoring and management showcase
6. 5-minute Q&A preparation with common questions

Include speaker notes, timing cues, and backup plans if something goes wrong.
```

### Prompt 7.2: Backup Plans & Troubleshooting
```
Help me prepare for demo day contingencies:

1. Pre-deployed backup environment in case of failures
2. Screenshot/video backups of key demo points
3. Common failure scenarios and quick fixes
4. Alternative demo flows if certain components fail
5. Presenter notes for technical difficulties
6. Quick environment reset procedures
7. Post-demo cleanup checklist
8. Follow-up materials for attendees

Include a pre-demo checklist to validate everything is working.
```

---

## 🚀 Quick Execution Checklist

Use this checklist to track your progress:

- [ ] **Phase 1 Complete** - Project structure and Git setup
- [ ] **Phase 2 Complete** - All Terraform modules working
- [ ] **Phase 3 Complete** - .NET application running locally
- [ ] **Phase 4 Complete** - CI/CD pipelines configured
- [ ] **Phase 5 Complete** - Documentation finished
- [ ] **Phase 6 Complete** - Everything tested and validated
- [ ] **Phase 7 Complete** - Demo script rehearsed

## 💡 Pro Tips for Tomorrow

1. **Start with Phase 1-2** - Get infrastructure working first
2. **Test frequently** - Validate each phase before moving on
3. **Use the provided artifacts** - We've already created much of this
4. **Focus on core demo** - Skip optional features if running short on time
5. **Rehearse once** - Do a full run-through before the actual demo

## 🆘 Emergency Shortcuts

If you're running out of time:

1. **Use provided artifacts** - Much of the code is already created above
2. **Focus on dev environment only** - Skip staging/prod for initial demo
3. **Pre-deploy infrastructure** - Have it ready before the demo
4. **Use screenshots** - For any failing components during live demo

Good luck with your demo tomorrow! 🎉