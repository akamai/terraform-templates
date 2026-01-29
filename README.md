[![Release to Prod](https://github.com/akamai/terraform-templates/actions/workflows/release.yml/badge.svg)](https://github.com/akamai/terraform-templates/actions/workflows/release.yml)

# Professional Services Terraform Templates

Streamline your Akamai deployment with production-ready Terraform templates for delivery and security configurations. This repository provides automated, best-practice implementations for Application Security (AAP/AAP+ASM) and Property Manager configurations.

## Overview

The [ps-terraform-templates repository](https://git.source.akamai.com/projects/GSS-DEVOPS/repos/ps-terraform-templates/browse) enables rapid deployment of Akamai configurations through:
- ✅ Pre-built, validated Terraform modules
- ✅ Automated deployment scripts with built-in validation
- ✅ Multi-environment support (dev, qa, prod)
- ✅ Product ID validation for security configurations
- ✅ Integrated activation workflows

## Quick Start

### Prerequisites

**System Requirements:**
- Terraform >= 1.9.0
- PowerShell 7+ (for deployment automation)
- Akamai PowerShell module 2.2.0
- Git

**Platform-Specific Setup:**
- **macOS**: [Setup Guide](https://git.source.akamai.com/users/joanders/repos/goldload-gs-macos/browse)
- **Windows**: [Setup Guide](https://ac-aloha.akamai.com/home/ls/community/apj-services-community/post/4240930785053181)

## Repository Structure

```
ps-terraform-templates/
├── deploy.ps1                      # Automated deployment script
├── new-aap-configuration/          # AAP security template
│   ├── environments/               # Support for multiple environments
│   │   ├── dev/
│   │   ├── qa/
│   │   └── prod/
│   ├── main.tf
│   ├── variables.tf
│   └── README.md
├── new-aapasm-configuration/       # AAP+ASM security template
├── new-property/                   # Delivery configuration template
└── README.md
```

## Akamai API Configuration

### 1. Create API Credentials

Navigate to **Akamai Control Center → Identity & Access Management**:

1. Create an API client with appropriate permissions:
   - **Property Manager API (PAPI)** (for delivery configurations)
   - **Application Security API** (for AAP/AAP+ASM)
   - **Bot Manager API** (for bot management features)
   - **Client Lists API** (for client lists)
2. Generate credentials: `client_secret`, `access_token`, `client_token`, `host`

### 2. Get Account Switch Key

For multi-account access, retrieve your account switch key:

```powershell
Get-AccountSwitchKey "<Account Name>"
```

> **Note:** Requires Akamai PowerShell module version >= 2.2.0

### 3. Configure `.edgerc` File

Create or update `~/.edgerc` with your credentials and account switch key:

```ini
[default]
client_secret = your_client_secret
access_token = your_access_token
client_token = your_client_token
host = your_api_host
account_key = your_account_switch_key  # Optional, for account switching
```

### 2. Clone Repository

```bash
git clone ssh://git@git.source.akamai.com:7999/gss-devops/ps-terraform-templates.git
cd ps-terraform-templates
```

## Available Templates

### 🔒 new-aap-configuration
App & API Protector:
- All AAP features
- Bot Management (BVM/BMS)
- Client Lists

**Valid Product IDs:** `M-LC-169584`, `M-LC-169585`

### 🔒 new-aapasm-configuration
App & API Protector with Advanced Security Management:
- All AAP features
- Bot Management (BVM/BMS)
- Client Reputation Protection
- Client Lists

**Valid Product IDs:** `M-LC-169586`, `M-LC-169587`

### 🚀 new-property
Delivery configuration templates for:
- DSA (Dynamic Site Accelerator)
- ION Standard

## Usage

### Deployment Workflow

The `deploy.ps1` script automates the entire deployment lifecycle with built-in validation:

| Parameter | Description |
|-----------|-------------|
| First Argument | Template to deploy: `aap`, `aapasm`, or `pm` |
| `-Env` | Target environment: `dev`, `qa`, or `prod` |
| `-Save` | Save configuration without activation |
| `-ActivateStaging` | Activate to Akamai staging network |
| `-ActivateProduction` | Activate to Akamai production network |
| `-Notes` | Version/activation notes (prompted if not provided) |
| `-Dry` | Show Terraform plan without applying changes |
| `-Destroy` | Deactivate and remove all resources |
| `-Debug` | Enable detailed logging to `akamai_tf.log` |
| `-SkipValidation` | Skip product ID validation |
| `-Help` | Display detailed help information |

### Configuration

Each template has environment-specific configurations in `environments/{env}/{env}.tfvars`:

```hcl
# Common variables
edgerc_path    = "~/.edgerc"
edgerc_section = "tf-aap"
environment    = "dev"
group_name     = "Your-Group-Name"
config_name    = "dev-security-config"
hostnames      = ["dev.example.com"]

# Enable/disable features
enable_waf       = true
enable_botman    = true
enable_rate      = true
...
```

Further environments can be created by replicating and adjusting each `environments/{env}/{env}.tfvars`.  
Refer to each template's `README.md` for detailed configuration options.

### Examples

```powershell
# Basic syntax
.\deploy.ps1 <template> -Env <environment> [options]

# Save configuration without activation
.\deploy.ps1 aap -Env dev -Save -Notes "Initial WAF rules"

# Activate to staging
.\deploy.ps1 aapasm -Env qa -ActivateStaging -Notes "QA validation"

# Activate to production
.\deploy.ps1 aap -Env prod -ActivateProduction -Notes "Production release"

# Activate to both networks
.\deploy.ps1 aapasm -Env prod -ActivateStaging -ActivateProduction

# Dry run (plan only, no changes)
.\deploy.ps1 aap -Env dev -Save -Dry

# Skip product ID validation
.\deploy.ps1 aapasm -Env qa -Save -SkipValidation
```

## Troubleshooting

### Common Issues

**Product validation fails:**
```
Product validation failed: No valid product ID found
```
- Verify your contract has the correct product entitlement.
- Check `edgerc_section` matches your `.edgerc` configuration
- Confirm account switch key is correct

**Terraform init fails:**
```
Error: Failed to query available provider packages
```
- Check internet connectivity
- Verify Terraform version >= 1.9.0
- Run `terraform init -upgrade`

**API authentication errors:**
```
Error: API authentication failed
```
- Verify `.edgerc` credentials are correct
- Check API client permissions in Identity & Access Management
- Ensure `edgerc_path` in tfvars points to correct file

**State file conflicts:**
- Each environment maintains separate state files
- Never manually edit state files
- Use `terraform state` commands for state management in necessary only

### Debug Mode

Enable detailed logging:

```powershell
.\deploy.ps1 aap -Env dev -Save -Debug
```

Logs are written to: `environments/{env}/{env}-akamai_tf.log`

## Provider Information

This repository uses:

```hcl
terraform {
  required_providers {
    akamai = {
      source  = "akamai/akamai"
      version = "~> 9.0"
    }
  }
  required_version = ">= 1.9.0"
}
```

## Tips for Structuring TF Templates (Best Practices)

### Terraform Structure
1. ✅ Use meaningful, descriptive variable names
2. ✅ Keep modules focused and reusable
3. ✅ Document complex logic with inline comments
4. ✅ Use `.gitignore` to exclude `.terraform/` and `*.tfstate` files
5. ✅ Store state files securely (not in version control)

### Deployment Process
1. ✅ Test in `dev` environment first
2. ✅ Use `-Dry` flag to preview changes
3. ✅ Promote through environments (e.g. dev → qa → prod)
4. ✅ Include descriptive activation notes
5. ✅ Monitor activations in Control Center

### Security
1. ✅ Protect `.edgerc` with appropriate file permissions
2. ✅ Use separate API credentials per environment when possible
3. ✅ Rotate API credentials regularly
4. ✅ Never commit credentials to version control

## Resources & Support

### Documentation
- [Akamai Terraform Provider](https://techdocs.akamai.com/terraform/docs/overview)
- [EMEA Professional Services DevOps Trainings](https://ac-aloha.akamai.com/home/ls/content/5535721256386560/emea-ps-devops-2023)
- [Terraform Best Practices](https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices)

### Support Channels
- [Webex Space: Terraform Templates Support](webexteams://im?space=52d5bcf0-42d2-11f0-9dd9-91df9cb369f0)
- Open an issue in this repository
- Contact Professional Services Terraform Templates team

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:
- Submitting bug reports
- Proposing new features
- Code style and standards
- Pull request process

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes.

---

**Maintained by:** Akamai Professional Services - Terraform templates Team  
**License:** Internal Use Only 