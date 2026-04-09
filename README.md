[![Release to Prod](https://github.com/akamai/terraform-templates/actions/workflows/release.yml/badge.svg)](https://github.com/akamai/terraform-templates/actions/workflows/release.yml)

# Professional Services Terraform Templates

Streamline your Akamai deployment with production-ready Terraform templates for delivery and security configurations, certificates and more. This repository provides automated, best-practice implementations for such configurations.

For standalone snippets, individual examples, and additional tooling, visit the [terraform-examples](https://github.com/akamai/terraform-examples) repository instead.

## Overview

The contents of this repository enables rapid deployment of Akamai configurations through:
- ✅ Pre-built, validated Terraform modules
- ✅ Automated deployment scripts with built-in validation
- ✅ Multi-environment support (e.g. dev, qa, prod)
- ✅ Product ID validation for security configurations
- ✅ Integrated activation workflows

## Quick Start

### Prerequisites

**System Requirements:**
- Terraform >= 1.9.0
- PowerShell 7+ (for deployment automation)
- Akamai PowerShell module 2.2.0
- Git

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
├── new-bmp-endpoints/              # Bot Manager Premier template
│   ├── environments/               # Support for multiple environments
│   │   ├── dev/
│   │   ├── qa/
│   │   └── prod/
│   ├── main.tf
│   ├── variables.tf
│   └── README.md
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
git clone https://github.com/akamai/terraform-templates.git
cd terraform-templates
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

### 🤖 new-bmp-endpoints
Bot Manager Premier:
- API Definition management (schema + operations)
- Transactional endpoint protection
- Security configuration activation
- Two-phase deployment model (API Definition → Security Config)

### 🚀 new-property
Delivery configuration templates for:
- DSA (Dynamic Site Accelerator)
- ION Standard

### 🔑 new-dv-san-cert
Certificate Provisioning System for:
- DV San Certificate

### 🔑 new-third-party-cert
Certificate Provisioning System for:
- Third Party Certificate

## Usage

### Deployment Workflow

The `deploy.ps1` script automates the entire deployment lifecycle with built-in validation:

#### Security and Delivery Templates (AAP, AAP+ASM, PM)

| Parameter | Description |
|-----------|-------------|
| First Argument | Template to deploy: `aap`, `aapasm`, or `pm` |
| `-Env` | Target environment: `dev`, `qa`, `prod`, etc. |
| `-Save` | Save configuration without activation |
| `-ActivateStaging` | Activate to Akamai staging network |
| `-ActivateProduction` | Activate to Akamai production network |
| `-Notes` | Version/activation notes (prompted if not provided) |
| `-Dry` | Show Terraform plan without applying changes |
| `-Destroy` | Deactivate and remove all resources |
| `-Debug` | Enable detailed logging to `akamai_tf.log` |
| `-SkipValidation` | Skip product ID validation |
| `-Help` | Display detailed help information |

#### Certificate Provisioning System (CPS) Templates

| Parameter | Description |
|-----------|-------------|
| First Argument | `cps` - Certificate Provisioning System |
| `-CpsType` | Certificate type: `dv-san-cert` or `third-party-cert` |
| `-CreateCert` | Certificate identifier to create |
| `-UploadCert` | Certificate identifier to upload (third-party only) |
| `-DestroyCert` | Certificate identifier to destroy |
| `-Debug` | Enable detailed logging to `akamai_tf.log` |
| `-Help` | Display detailed help information |

> **Note:** CPS templates do not use `-Env`, `-Save`, `-ActivateStaging`, `-ActivateProduction`, `-Notes`, or `-SkipValidation` parameters.

#### Bot Manager Premier (BMP) Template

> BMP uses a two-phase deployment model. Save and Activate are always separate commands.

| Parameter | Phase | Description |
|-----------|-------|-------------|
| `bmp` | — | Template type for Bot Manager Premier |
| `-Env` | — | Target environment: `dev`, `qa`, `prod`, etc. |
| `-SaveApi` | Phase 1 | Save the API definition without activating |
| `-ActivateStagingApi` | Phase 1 | Activate API definition to staging. Can combine with `-ActivateProductionApi` |
| `-ActivateProductionApi` | Phase 1 | Activate API definition to production. Can combine with `-ActivateStagingApi` |
| `-SaveSec` | Phase 2 | Save security config (requires Phase 1 activated first) |
| `-ActivateStagingSec` | Phase 2 | Activate security config to staging (requires API activated to staging) |
| `-ActivateProductionSec` | Phase 2 | Activate security config to production (requires API activated to production) |
| `-Notes` | Phase 2 | Version/activation notes (prompted if not provided) |
| `-Dry` | Both | Show Terraform plan without applying changes |
| `-Destroy` | — | Deactivate and remove all BMP resources |
| `-Debug` | Both | Enable detailed logging |

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

# Create a DV SAN certificate
.\deploy.ps1 cps -CpsType dv-san-cert -CreateCert cert1

# Create a third-party certificate
.\deploy.ps1 cps -CpsType third-party-cert -CreateCert cert1

# Upload a third-party certificate (after creating)
.\deploy.ps1 cps -CpsType third-party-cert -UploadCert cert1

# Destroy a certificate
.\deploy.ps1 cps -CpsType dv-san-cert -DestroyCert cert1

# --- BMP (Bot Manager Premier) ---

# Phase 1: Save the API definition
.\deploy.ps1 bmp -Env dev -SaveApi

# Phase 1: Activate API definition to staging
.\deploy.ps1 bmp -Env dev -ActivateStagingApi

# Phase 1: Activate to both networks simultaneously
.\deploy.ps1 bmp -Env dev -ActivateStagingApi -ActivateProductionApi

# Phase 2: Save the security config (Phase 1 must be activated first)
.\deploy.ps1 bmp -Env dev -SaveSec -Notes "Initial BMP setup"

# Phase 2: Activate security config to staging
.\deploy.ps1 bmp -Env dev -ActivateStagingSec

# Phase 2: Activate security config to production
.\deploy.ps1 bmp -Env dev -ActivateProductionSec

# Destroy all BMP resources
.\deploy.ps1 bmp -Env dev -Destroy
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

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on collaborating to this repository.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes.

---

**Maintained by:** Akamai Professional Services - Terraform Templates Team