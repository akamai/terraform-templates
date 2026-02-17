<!-- BEGIN_TF_DOCS -->

# Akamai DV SAN Certificate Enrollment Module

This Terraform module automates the creation and management of **Akamai Certificate Provisioning System (CPS)** enrollments for **Domain Validated (DV)** certificates with **Subject Alternative Names (SANs)**.

The module supports configuration of administrative and technical contacts, CSR generation, network and TLS configurations, After creation, the module automatically outputs DNS and HTTP challenge details into [dns-challenges.txt] and [http-challenges.txt]

## Prerequisites

- Terraform v1.4+  
- Akamai Terraform Provider installed  
- Access to an Akamai account with CPS permissions  
- `.edgerc` file configured with proper credentials
- **Recommendation**: Use a dedicated .edgerc section per account for clean separation.

## Project Structure

├── provider.tf
├── main.tf
├── variables.tf
├── terraform.tfvars
├── files.tf
└── dns-challenges.txt / http-challenges.txt

### File Overview

| File | Description |
|------|--------------|
| **main.tf** | Core Terraform logic for Akamai CPS enrollment and configuration. |
| **variables.tf** | Declares all configurable variables with types and descriptions. |
| **terraform.tfvars** | Example values for user configuration (to be customized). |
| **files.tf** | Writes DNS and HTTP challenge details to local text files for validation. |
| **dns-challenges.txt** | contains DNS validation records (CNAME or TXT values),Generated at root after apply
| **http-challenges.txt** |contains HTTP validation tokens and paths,Generated at root after apply

**Usage**
- Update your terraform.tfvars with project-specific values.
- Initialize Terraform: **terraform init**
- Review the plan: **terraform plan**
- Apply the configuration: **terraform apply**
- After successful execution, check the root folder for **dns-challenges.txt** and **http-challenges.txt**

**Output artifacts**
- After successful enrollment creation in CPS, two files will be written at the root:
    [dns-challenges.txt] → contains all DNS-based validation records
    [http-challenges.txt] → contains all HTTP-based validation details

- Each file includes the domain, path (or CNAME), and target value to be configured for CPS validation.

- Files are created at the root path (where Terraform is executed) and not inside the module.This separation ensures output visibility and avoids overwriting module files.

**terraform.tfvars**
- This file defines all input variables used by the DV SAN Certificate module.
Update the placeholders (<...>) with actual customer or project-specific values before running Terraform.

## Note

- Set [acknowledge\_pre\_verification\_warnings] = [true] only after confirming CPS warnings are acceptable.

- If you don’t set this flag to true, Terraform will fail the run with a error message such as **Enrollment cannot proceed until you acknowledge pre-verification warnings**

- Only set it to false if you want to manually review and accept warnings through the Akamai Control Center UI before proceeding.

- [sni\_only] = set it to [true] or [false] depending on the requirement.

# Usage
Basic usage of this module is as follows:

```hcl
module "example" {
  	 source  = "<module-location>"
  
	 # Required variables
  	 admin_contact  = <object({
    first_name       = string
    last_name        = string
    organization     = string
    email            = string
    phone            = string
    address_line_one = string
    city             = string
    region           = string
    postal_code      = string
    country_code     = string
  })>
  	 cert_name  = <string>
  	 common_name  = <string>
  	 contract_id  = <string>
  	 csr  = <object({
    country_code        = string
    city                = string
    organization        = string
    organizational_unit = string
    state               = string
  })>
  	 edgerc_section  = <string>
  	 network_configuration  = <object({
    disallowed_tls_versions = list(string)
    clone_dns_names         = bool
    geography               = string
    must_have_ciphers       = string
    ocsp_stapling           = string
    preferred_ciphers       = string
  })>
  	 organization  = <object({
    name             = string
    phone            = string
    address_line_one = string
    address_line_two = string
    city             = string
    region           = string
    postal_code      = string
    country_code     = string
  })>
  	 tech_contact  = <object({
    first_name       = string
    last_name        = string
    organization     = string
    email            = string
    phone            = string
    address_line_one = string
    city             = string
    region           = string
    postal_code      = string
    country_code     = string
  })>
  
	 # Optional variables
  	 acknowledge_pre_verification_warnings  = <bool> | default: true
  	 allow_duplicate_common_name  = <bool> | default: false
  	 certificate_chain_type  = <string> | default: "default"
  	 edgerc_path  = <string> | default: "~/.edgerc"
  	 sans  = <list(string)> | default: []
  	 secure_network  = <string> | default: "enhanced-tls"
  	 signature_algorithm  = <string> | default: "SHA-256"
  	 sni_only  = <bool> | default: true
}
 ```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_akamai"></a> [akamai](#requirement\_akamai) | ~> 9.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.6 |

## Resources

| Name | Type |
|------|------|
| [local_file.dns_challenges_details](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.http_challenges_details](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_dv-san-cert"></a> [dv-san-cert](#module\_dv-san-cert) | git::ssh://git@github.com/akamai/terraform-templates-modules.git//dv-san-cert | v1.1.2 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_contact"></a> [admin\_contact](#input\_admin\_contact) | Admin contact details. | <pre>object({<br/>    first_name       = string<br/>    last_name        = string<br/>    organization     = string<br/>    email            = string<br/>    phone            = string<br/>    address_line_one = string<br/>    city             = string<br/>    region           = string<br/>    postal_code      = string<br/>    country_code     = string<br/>  })</pre> | n/a | yes |
| <a name="input_cert_name"></a> [cert\_name](#input\_cert\_name) | Certificate name / identifier (e.g. cert1) | `string` | n/a | yes |
| <a name="input_common_name"></a> [common\_name](#input\_common\_name) | Primary common name for the certificate. | `string` | n/a | yes |
| <a name="input_contract_id"></a> [contract\_id](#input\_contract\_id) | Akamai contract ID. | `string` | n/a | yes |
| <a name="input_csr"></a> [csr](#input\_csr) | Certificate Signing Request details. | <pre>object({<br/>    country_code        = string<br/>    city                = string<br/>    organization        = string<br/>    organizational_unit = string<br/>    state               = string<br/>  })</pre> | n/a | yes |
| <a name="input_edgerc_section"></a> [edgerc\_section](#input\_edgerc\_section) | Section in the .edgerc file.<br/><br/>    For professional services, it is recommended to create a new section for<br/>    each account managed. | `string` | n/a | yes |
| <a name="input_network_configuration"></a> [network\_configuration](#input\_network\_configuration) | TLS and network configuration settings. | <pre>object({<br/>    disallowed_tls_versions = list(string)<br/>    clone_dns_names         = bool<br/>    geography               = string<br/>    must_have_ciphers       = string<br/>    ocsp_stapling           = string<br/>    preferred_ciphers       = string<br/>  })</pre> | n/a | yes |
| <a name="input_organization"></a> [organization](#input\_organization) | Organization details for the enrollment. | <pre>object({<br/>    name             = string<br/>    phone            = string<br/>    address_line_one = string<br/>    address_line_two = string<br/>    city             = string<br/>    region           = string<br/>    postal_code      = string<br/>    country_code     = string<br/>  })</pre> | n/a | yes |
| <a name="input_tech_contact"></a> [tech\_contact](#input\_tech\_contact) | Technical contact details. | <pre>object({<br/>    first_name       = string<br/>    last_name        = string<br/>    organization     = string<br/>    email            = string<br/>    phone            = string<br/>    address_line_one = string<br/>    city             = string<br/>    region           = string<br/>    postal_code      = string<br/>    country_code     = string<br/>  })</pre> | n/a | yes |
| <a name="input_acknowledge_pre_verification_warnings"></a> [acknowledge\_pre\_verification\_warnings](#input\_acknowledge\_pre\_verification\_warnings) | Acknowledge warnings before verification. | `bool` | `true` | no |
| <a name="input_allow_duplicate_common_name"></a> [allow\_duplicate\_common\_name](#input\_allow\_duplicate\_common\_name) | Whether to allow duplicate common names. | `bool` | `false` | no |
| <a name="input_certificate_chain_type"></a> [certificate\_chain\_type](#input\_certificate\_chain\_type) | Certificate chain type (default or test). | `string` | `"default"` | no |
| <a name="input_edgerc_path"></a> [edgerc\_path](#input\_edgerc\_path) | n/a | `string` | `"~/.edgerc"` | no |
| <a name="input_sans"></a> [sans](#input\_sans) | List of Subject Alternative Names (SANs). | `list(string)` | `[]` | no |
| <a name="input_secure_network"></a> [secure\_network](#input\_secure\_network) | Secure network type. Valid values: enhanced-tls, standard-tls. | `string` | `"enhanced-tls"` | no |
| <a name="input_signature_algorithm"></a> [signature\_algorithm](#input\_signature\_algorithm) | Signature algorithm (e.g., SHA-256). | `string` | `"SHA-256"` | no |
| <a name="input_sni_only"></a> [sni\_only](#input\_sni\_only) | Whether to enable SNI-only. | `bool` | `true` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->