<!-- BEGIN_TF_DOCS -->

# Bot Manager Premier (BMP) — Terraform Templates

Automate the deployment, activation, and teardown of Akamai Bot Manager Premier endpoint configurations using Terraform and PowerShell.

---

## How It Works

BMP uses a **two-phase activation model**. You must complete Phase 1 before Phase 2.

```
Phase 1 — API Definition          Phase 2 — Security Config
┌──────────────────────────┐      ┌────────────────────────────────┐
│  SaveApi                 │      │  SaveSec                       │
│  ActivateStagingApi      │─────▶│  ActivateStagingSec            │
│  ActivateProductionApi   │      │  ActivateProductionSec         │
└──────────────────────────┘      └────────────────────────────────┘
 target: module.api_definition     target: module.transactional_endpoint
                                          module.security_config_activation
```

**Phase 1** creates and optionally activates the API definition (schema, hostnames, resources).
**Phase 2** creates the transactional endpoint / security config and activates it. Phase 2 **requires** Phase 1 to be activated on the same network first.

There are also **global activation** flags (`-ActivateStaging`, `-ActivateProduction`) that are not scoped to a specific module target.

---

## Prerequisites

- **Terraform** installed and on your `PATH`
- **PowerShell 7+** (cross-platform)
- **Akamai EdgeGrid credentials** — an `.edgerc` file (default path: `~/.edgerc`) with valid API tokens
- **Akamai Contract & Group** — your contract ID and group ID
- **Security Config** — an existing AppSec configuration name and security policy name

---

## Getting Started — End-to-End Setup

This section walks you through the entire process from scratch — from credentials to a fully deployed BMP configuration.

### Step 1: Set Up Your Akamai Credentials

Create or verify your `.edgerc` file (default location: `~/.edgerc`):

```ini
[default]
client_secret = your_client_secret
host = your_host
access_token = your_access_token
client_token = your_client_token
```

You can use a different path or section name — just set `edgerc_path` and `edgerc_section` in your `.tfvars` (see Step 5).

Alternatively, uncomment the environment-variable provider block in `provider.tf` to use inline credentials.

### Step 2: Create Your Environment Folder

The `environments/` folder already exists inside the template folder. Create a subfolder for your environment:

```
new-bmp-endpoints/environments/<env>/
```

For example: `new-bmp-endpoints/environments/qa/`

This folder will contain your `.tfvars` file and will also store auto-generated files during deployments (`.tfplan`, `.tfstate`, `config.backend`).

### Step 3: Define Your API Schema (`.yml`)

> **Tip:** Use the AI chatbot prompt in `BMP_CHATBOT_PROMPT.md` to generate your `.yml` file automatically.
> Paste the prompt into ChatGPT, Gemini, Claude, or any AI chatbot — it will ask you guided questions and produce a ready-to-use schema file.
> Use this manual approach only if you prefer to fill the file directly.

Copy `Schema_sample.yml` to the **template folder root** (same level as `main.tf`) and rename it (e.g. `api1.yml`). Fill in your values:

```yaml
openapi: 3.0.1

info:
  title: My API Name                        # Your API's display name

servers:
- url: api.example.com/v1                   # Your API hostname + base path

x-akamai-api-definitions:
  contractId: 1-ABC123                       # Your Akamai contract ID (without ctr_ prefix)
  groupId: 12345                             # Your Akamai group ID (without grp_ prefix)
  matchCaseSensitive: false
  constraints:                               # Required for AAP+ASM; remove if not needed
    enforceOn:
      request: true

paths:
  /login:                                    # Your API resource path
    x-akamai-api-definitions-resource:
      name: "login"                          # Resource name
    post:                                    # HTTP method (get | post | put | delete | patch)
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                username:
                  type: string
                password:
                  type: string
```

To add **multiple hostnames** for the same API, add more entries under `servers`. To add **more resources**, duplicate the block under `paths` for each endpoint. See `schema.txt` for the full reference including versioning, XML/URL-encoded bodies, header/cookie/query parameters, and more.

**If you have multiple APIs**, create a separate `.yml` file for each one (e.g. `api1.yml`, `api2.yml`) in the same template folder root.

### Step 4: Define Your Operations JSON

> **Tip:** Use the AI chatbot prompt in `BMP_CHATBOT_PROMPT.md` to generate your operations JSON file automatically.
> Paste the prompt into ChatGPT, Gemini, Claude, or any AI chatbot — it will ask you guided questions and produce a ready-to-use operations file.
> Use this manual approach only if you prefer to fill the file directly.

For each API schema file, create a matching operations JSON file in the **template folder root**. This maps each resource path to its operations — including the HTTP method, purpose, request parameters, and origin response conditions (success and failure).

Copy `operations_sample.json`, rename it (e.g. `operations-api.json`), and modify it for your API. See `operations.txt` for detailed guidance on every field.

**Minimal example** — a simple endpoint with no parameters or conditions:

```json
{
  "operations": {
    "/search": {
      "search": {
        "method": "POST",
        "purpose": "SEARCH"
      }
    }
  }
}
```

**Full example** — multiple operations on one path with parameters, success conditions, and failure conditions:

```json
{
  "operations": {
    "/login": {
      "login": {
        "method": "POST",
        "purpose": "LOGIN",
        "parameters": {
          "username": {
            "path": ["application/json", "username"],
            "location": "BODY"
          }
        },
        "successConditions": [
          {
            "positiveMatch": true,
            "type": "HTTP_STATUS",
            "values": ["200"]
          }
        ],
        "failureConditions": [
          {
            "positiveMatch": true,
            "type": "HTTP_STATUS",
            "values": ["401", "403"]
          }
        ]
      },
      "create_account": {
        "method": "POST",
        "purpose": "ACCOUNT_CREATION",
        "parameters": {
          "userEmail": {
            "path": ["application/json", "email"],
            "location": "BODY",
            "usedForLogin": true
          }
        },
        "successConditions": [
          {
            "headerName": "x-status",
            "positiveMatch": true,
            "suppressFromClientResponse": false,
            "type": "HEADER_VALUE",
            "valueCase": false,
            "valueWildcard": false,
            "values": ["success"]
          }
        ],
        "failureConditions": [
          {
            "headerName": "x-status",
            "positiveMatch": true,
            "suppressFromClientResponse": false,
            "type": "HEADER_VALUE",
            "valueCase": false,
            "valueWildcard": false,
            "values": ["error", "denied"]
          }
        ]
      }
    }
  }
}
```

**Quick reference:**

| Field | Description |
|---|---|
| `method` | HTTP method: `POST`, `GET`, `PUT`, `DELETE`, `PATCH` |
| `purpose` | `LOGIN`, `SEARCH`, `ACCOUNT_CREATION`, `ACCOUNT_VERIFICATION`, `PASSWORD_RESET` |
| `parameters` | Request parameters to inspect. Each has `path` (array of JSON keys), `location` (`BODY`/`HEADER`/`QUERY`/`COOKIE`), and optional `usedForLogin` flag |
| `successConditions` | What defines a successful origin response: `HTTP_STATUS` (match status codes) or `HEADER_VALUE` (match a response header) |
| `failureConditions` | What defines a failed origin response: same structure as `successConditions`. Responses matching neither are also reported as failure |

For optimal bot protection, define **both** `successConditions` and `failureConditions` so Bot Manager can accurately classify origin responses.

If you have multiple APIs, create a separate operations file for each (e.g. `operations-api.json`, `operations-api2.json`).

### Step 5: Create Your `.tfvars` File

Create `<env>.tfvars` inside your environment folder (e.g. `environments/qa/prod.tfvars`). This ties everything together:

```hcl
# ─────────────────────────────────────────────
# Common Variables
# ─────────────────────────────────────────────
edgerc_path     = "~/.edgerc"
edgerc_section  = "services"
group_name      = "Akamai Professional Services-1-1NC95D"

apis = {
  api1 = "api1.yml"
  api2 = "api2.yml"
  # api3 = "api3.yml"                        # uncomment to add more APIs
}

operations = {
  api1 = "operations-api.json"
  api2 = "operations-api2.json"
  # op3 = "op3.json"
}

config_name = "MySecurityConfig"
policy_name = "tf-demo"

javascript_hostnames = ["sharath.gslab-akashop.com"]
injection_type       = "ALWAYS"              # NEVER, AROUND_PROTECTED_OPERATIONS, ALWAYS

expect_inline_traffic   = true
expect_sdk_traffic      = true
expect_standard_traffic = false
```

> **Note:** The `apis` and `operations` paths are relative to the template folder root (where `main.tf` lives), so you only need the filename — no folder prefix.

### Step 6: Deploy

Run the two-phase deployment:

```powershell
# Phase 1 — Save the API definition
.\deploy.ps1 bmp -Env qa -SaveApi

# Phase 1 — Activate the API definition to staging
.\deploy.ps1 bmp -Env qa -ActivateStagingApi

# Phase 2 — Save the security config
.\deploy.ps1 bmp -Env qa -SaveSec

# Phase 2 — Activate the security config to staging
.\deploy.ps1 bmp -Env qa -ActivateStagingSec

# When ready for production:
.\deploy.ps1 bmp -Env qa -ActivateProductionApi
.\deploy.ps1 bmp -Env qa -ActivateProductionSec
```

You will be prompted for version/activation notes, or pass them inline with `-VersionNotes "your notes"`.

### Adding Another API Later

To add a new API to an existing setup:

1. Create a new `.yml` schema file and matching operations `.json` file in the **template folder root** (alongside the existing `api1.yml`, `api2.yml`).
2. Add the new key to both `apis` and `operations` maps in your `.tfvars`:

```hcl
apis = {
  api1 = "api1.yml"
  api2 = "api2.yml"
  api3 = "api3.yml"                          # new
}

operations = {
  api1 = "operations-api.json"
  api2 = "operations-api2.json"
  op3  = "operations-api3.json"              # new
}
```

3. Re-run the Phase 1 then Phase 2 workflow.

---

## Project Structure

```
terraform-templates/
├── deploy.ps1                              # Entry-point script
├── lib/
│   └── templates/
│       └── BMP.psm1                        # PowerShell module (deployment logic)
├── new-bmp-endpoints/                      # BMP template folder
│   ├── main.tf                             # Terraform root: api_definition,
│   │                                       #   transactional_endpoint, security_config_activation
│   ├── variables.tf                        # Input variables
│   ├── outputs.tf                          # Outputs (api definition, config_id)
│   ├── provider.tf                         # Akamai provider config
│   ├── .terraform.lock.hcl
│   ├── api1.yml                            # OpenAPI schema for API 1
│   ├── api2.yml                            # OpenAPI schema for API 2
│   ├── operations-api.json                 # Operation definitions for API 1
│   ├── operations-api2.json                # Operation definitions for API 2
│   ├── Schema_sample.yml                   # Template: copy and rename for new APIs
│   ├── schema.txt                          # Detailed schema reference guide
│   ├── operations_sample.json              # Template: copy and rename for new operations
│   ├── operations.txt                      # Detailed operations reference guide
│   ├── BMP_CHATBOT_PROMPT.md               # AI chatbot prompt — generates .yml and operations JSON interactively
│   └── environments/
│       ├── dev/
│       ├── prod/
│       └── qa/
│           ├── prod.tfvars                 # Variable values for this env
│           ├── config.backend              # Terraform backend config (auto-generated)
│           ├── prod-terraform.tfstate      # State file (auto-generated)
│           ├── prod-terraform.tfstate.backup
│           ├── prod-api-save.tfplan        # Plan files (auto-generated)
│           ├── prod-api-staging.tfplan
│           ├── prod-sec-save.tfplan
│           ├── prod-sec-staging.tfplan
│           └── prod-staging.tfplan
├── new-aap-configuration/                  # AAP template (separate product)
└── new-aapasm-configuration/               # AAP+ASM template (separate product)
```

---

## Command Reference

All commands follow this pattern:

```powershell
.\deploy.ps1 bmp -Env <environment> <flags>
```

### Phase 1 — API Definition

**Save the API definition** (creates/updates without activating):

```powershell
.\deploy.ps1 bmp -Env qa -SaveApi
```

**Save, then activate to staging:**

```powershell
.\deploy.ps1 bmp -Env qa -SaveApi
.\deploy.ps1 bmp -Env qa -ActivateStagingApi
```

**Save, then activate to production:**

```powershell
.\deploy.ps1 bmp -Env qa -SaveApi
.\deploy.ps1 bmp -Env qa -ActivateProductionApi
```

**Activate to both networks:**

```powershell
.\deploy.ps1 bmp -Env qa -ActivateStagingApi -ActivateProductionApi
```

### Phase 2 — Security Configuration

> **Prerequisite:** Phase 1 must be activated on the target network before running Phase 2 commands.

**Save the security config** (requires API activation to exist in state):

```powershell
.\deploy.ps1 bmp -Env qa -SaveSec
```

**Activate security config to staging** (requires API activated to staging):

```powershell
.\deploy.ps1 bmp -Env qa -ActivateStagingSec
```

**Activate security config to production** (requires API activated to production):

```powershell
.\deploy.ps1 bmp -Env qa -ActivateProductionSec
```

### Global Activation

Activate the full configuration (not scoped to a specific module):

```powershell
.\deploy.ps1 bmp -Env qa -ActivateStaging
.\deploy.ps1 bmp -Env qa -ActivateProduction
```

### Dry Run

Preview the Terraform plan without applying changes:

```powershell
.\deploy.ps1 bmp -Env qa -SaveApi -Dry
```

### Debug Mode

Enable Terraform debug logging (logs saved to the environment folder):

```powershell
.\deploy.ps1 bmp -Env qa -SaveApi -Debug
```

### Version Notes

Supply version/activation notes inline (you will be prompted if omitted):

```powershell
.\deploy.ps1 bmp -Env qa -ActivateStagingSec -VersionNotes "JIRA-1234: updated rate limits"
```

### Destroy

Tear down the entire BMP configuration for an environment:

```powershell
.\deploy.ps1 bmp -Env qa -Destroy
```

---

## Typical Deployment Workflow

A full first-time deployment follows these steps in order:

```powershell
# 1. Save the API definition
.\deploy.ps1 bmp -Env qa -SaveApi

# 2. Activate the API definition to staging
.\deploy.ps1 bmp -Env qa -ActivateStagingApi

# 3. Save the security config
.\deploy.ps1 bmp -Env qa -SaveSec

# 4. Activate the security config to staging
.\deploy.ps1 bmp -Env qa -ActivateStagingSec

# 5. Validate on staging, then activate API definition to production
.\deploy.ps1 bmp -Env qa -ActivateProductionApi

# 6. Activate security config to production
.\deploy.ps1 bmp -Env qa -ActivateProductionSec
```

---

## Troubleshooting

### `SaveSec requires API activation (staging or production) to exist in state`

Phase 2 commands need Phase 1 to be activated first. Run one of:

```powershell
.\deploy.ps1 bmp -Env <env> -ActivateStagingApi
.\deploy.ps1 bmp -Env <env> -ActivateProductionApi
```

### `ActivateStagingSec requires API to be activated to STAGING first`

The security config can only be activated to a network where the API definition is already active.

```powershell
.\deploy.ps1 bmp -Env <env> -ActivateStagingApi     # then retry ActivateStagingSec
```

### `config_id value 0 specified in configuration differs from resource ID`

A change in the API definition has desynchronized the security config. Re-sync by running an API command first:

```powershell
.\deploy.ps1 bmp -Env <env> -SaveApi                 # or -ActivateStagingApi / -ActivateProductionApi
```

### `Variable is not assigned in the method` (ParserError)

This is a PowerShell class limitation. If you modify `BMP.psm1`, avoid using `$_` inside class methods. Use explicit `foreach` loops and always assign variables before use.

### Terraform apply failed — automatic retry

The deploy script retries `terraform apply` up to 2 times automatically. If it still fails, check the Terraform output for Akamai API errors (rate limits, validation issues, etc.).

# Usage
Basic usage of this module is as follows:

```hcl
module "example" {
  	 source  = "<module-location>"
  
	 # Required variables
  	 config_name  = <string>
  	 expect_inline_traffic  = <bool>
  	 expect_sdk_traffic  = <bool>
  	 expect_standard_traffic  = <bool>
  	 group_name  = <string>
  	 injection_type  = <string>
  	 javascript_hostnames  = <list(string)>
  	 policy_name  = <string>
  
	 # Optional variables
  	 activate_to_production  = <bool> | default: false
  	 activate_to_staging  = <bool> | default: false
  	 activation_to_production_exists  = <bool> | default: false
  	 activation_to_staging_exists  = <bool> | default: false
  	 apis  = <map(string)> | default: {
  "api1": "null"
}
  	 edgerc_path  = <string> | default: "~/.edgerc"
  	 edgerc_section  = <string> | default: "default"
  	 emails  = <list(string)> | default: [
  "noreply@akamai.com"
]
  	 enable_js_injection  = <string> | default: ""
  	 operations  = <map(string)> | default: {
  "api1": "null"
}
  	 version_notes  = <string> | default: "Initial Config"
}
 ```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_akamai"></a> [akamai](#requirement\_akamai) | >= 9.2.0 |

## Resources

| Name | Type |
|------|------|
| [akamai_contract.contract](https://registry.terraform.io/providers/akamai/akamai/latest/docs/data-sources/contract) | data source |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_api_definition"></a> [api\_definition](#module\_api\_definition) | git::ssh://git@github.com/akamai/terraform-templates-modules.git//bmp/api-definition | v1.3.0 |
| <a name="module_security_config_activation"></a> [security\_config\_activation](#module\_security\_config\_activation) | git::ssh://git@github.com/akamai/terraform-templates-modules.git//bmp/security-config-activation | v1.3.0 |
| <a name="module_transactional_endpoint"></a> [transactional\_endpoint](#module\_transactional\_endpoint) | git::ssh://git@github.com/akamai/terraform-templates-modules.git//bmp/transactional-endpoint | v1.3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_config_name"></a> [config\_name](#input\_config\_name) | Name of the existing AppSec security configuration. | `string` | n/a | yes |
| <a name="input_expect_inline_traffic"></a> [expect\_inline\_traffic](#input\_expect\_inline\_traffic) | Indicates whether inline traffic is expected. | `bool` | n/a | yes |
| <a name="input_expect_sdk_traffic"></a> [expect\_sdk\_traffic](#input\_expect\_sdk\_traffic) | Indicates whether SDK-based traffic is expected. | `bool` | n/a | yes |
| <a name="input_expect_standard_traffic"></a> [expect\_standard\_traffic](#input\_expect\_standard\_traffic) | Indicates whether standard traffic is expected. | `bool` | n/a | yes |
| <a name="input_group_name"></a> [group\_name](#input\_group\_name) | Akamai Group name under which resources will be managed. | `string` | n/a | yes |
| <a name="input_injection_type"></a> [injection\_type](#input\_injection\_type) | JavaScript injection mode. Allowed values: NEVER, AROUND\_PROTECTED\_OPERATIONS, ALWAYS. | `string` | n/a | yes |
| <a name="input_javascript_hostnames"></a> [javascript\_hostnames](#input\_javascript\_hostnames) | List of hostnames where JavaScript injection rules will apply. | `list(string)` | n/a | yes |
| <a name="input_policy_name"></a> [policy\_name](#input\_policy\_name) | Security policy name within the specified configuration. | `string` | n/a | yes |
| <a name="input_activate_to_production"></a> [activate\_to\_production](#input\_activate\_to\_production) | Set to true to activate resources to the PRODUCTION network. | `bool` | `false` | no |
| <a name="input_activate_to_staging"></a> [activate\_to\_staging](#input\_activate\_to\_staging) | Set to true to activate resources to the STAGING network. | `bool` | `false` | no |
| <a name="input_activation_to_production_exists"></a> [activation\_to\_production\_exists](#input\_activation\_to\_production\_exists) | Internal flag indicating whether a production activation already exists. | `bool` | `false` | no |
| <a name="input_activation_to_staging_exists"></a> [activation\_to\_staging\_exists](#input\_activation\_to\_staging\_exists) | Internal flag indicating whether a staging activation already exists. | `bool` | `false` | no |
| <a name="input_apis"></a> [apis](#input\_apis) | Map of logical API keys to OpenAPI specification files. | `map(string)` | <pre>{<br/>  "api1": "null"<br/>}</pre> | no |
| <a name="input_edgerc_path"></a> [edgerc\_path](#input\_edgerc\_path) | Path to the Akamai EdgeGrid authentication file (e.g. ~/.edgerc). | `string` | `"~/.edgerc"` | no |
| <a name="input_edgerc_section"></a> [edgerc\_section](#input\_edgerc\_section) | Section inside the edgerc file containing API credentials. | `string` | `"default"` | no |
| <a name="input_emails"></a> [emails](#input\_emails) | List of email addresses to receive activation notifications. | `list(string)` | <pre>[<br/>  "noreply@akamai.com"<br/>]</pre> | no |
| <a name="input_enable_js_injection"></a> [enable\_js\_injection](#input\_enable\_js\_injection) | Mandatory flag or value to enable JavaScript injection logic. DO NOT Delete | `string` | `""` | no |
| <a name="input_operations"></a> [operations](#input\_operations) | Map of logical API keys to operations definition JSON files. Keys must match the 'apis' map. | `map(string)` | <pre>{<br/>  "api1": "null"<br/>}</pre> | no |
| <a name="input_version_notes"></a> [version\_notes](#input\_version\_notes) | Version or activation notes applied during resource activation. | `string` | `"Initial Config"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api1"></a> [api1](#output\_api1) | n/a |
| <a name="output_config_id"></a> [config\_id](#output\_config\_id) | Akamai AppSec configuration ID resolved by name |
<!-- END_TF_DOCS -->