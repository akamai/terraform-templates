<!-- BEGIN_TF_DOCS -->

# Akamai Domain Ownership Management (DOM)

This Terraform configuration manages Akamai Domain Ownership validation for your properties.

## Overview

Prove ownership of new domains you onboard to Akamai before activating your property configuration. This prevents unauthorized use of hostnames on the Akamai network, which improves overall security.

There is a standard schedule of DOM background jobs (crons) and validates the domain straight away or after a short delay. You can use the `akamai_property_domainownership_validation` resource to validate your domains immediately.

## Workflow

## Step 1: Create Domain Ownership Records

Run Terraform in this directory to create the domain ownership records:

 ```
 terraform init
 terraform plan
 terraform apply
 ```

This creates the necessary records in Akamai and outputs the TXT record values you need to add to your DNS.

## Step 2: Configure DNS Records

Add the TXT or CNAME records from the Terraform output to your DNS provider. Wait for DNS propagation.

## Step 3: Validate Domains

After DNS records are in place, and you want to force a validation:

In the `terraform.tfvars` file update the `enable_validation = true`

 This triggers immediate validation of your domains instead of waiting for the background validation jobs.

## Configuration

## Domain Validation Entries

Configure your domains in `terraform.tfvars`:

```
 	     domain_validation_entries = [
         {
            domain_name      = "host.example.com"
            validation_scope = "HOST"
         },
         {
            domain_name      = "example.com"
            validation_scope = "DOMAIN"
        },
         {
            domain_name      = "*.wildcard.example.com"
            validation_scope = "WILDCARD"
         }
       ]
```

## Validation Scopes

  1. **HOST**: Use for exact domains. For example, blog.example.com validates only that specific hostname.
  2. **WILDCARD**: Use for first-level subdomains. For example, *.example.com validates blog.example.com and 123.example.com, but not xyz.blog.example.com or the apex example.com.
  3. **DOMAIN**: Use for exact domains and all subdomains. For example, example.com validates blog.example.com, 123.blog.example.com, x.123.blog.example.com, and the apex domain.

## Validation Rules

  1. Maximum of 1000 domain validation entries
  2. Validation scope must be HOST, DOMAIN, or WILDCARD (case-insensitive)
  3. HOST entries cannot overlap with DOMAIN entries (e.g., host.example.com conflicts with example.com)
  4. WILDCARD entries must start with *. and contain a valid base domain
  5. HOST and DOMAIN entries cannot use wildcard prefix

  ## Requirements

  ```
  Terraform >= 1.5
  Akamai Provider >= 9.2.0
  ```

  ## Akamai API Credentials

  The Akamai API user configured in your Terraform credentials must have the following access level:

  ```
  API Service: Domain Ownership Manager
  Access Level: READ-WRITE
  ```

  Configure this in your Akamai control panel when setting up API credentials. Ensure your .edgerc file references the correct section with these permissions.

# Usage
Basic usage of this module is as follows:

```hcl
module "example" {
  	 source  = "<module-location>"
  
	 # Required variables
  	 edgerc_section  = <string>
  
	 # Optional variables
  	 domain_search_entries  = <list(object({
	    domain_name      = string
	    validation_scope = string
	  }))> | default: []
  	 domain_validation_entries  = <list(object({
	    domain_name      = string
	    validation_scope = string
	    validation_method = optional(string, "DNS_TXT")  # Default to "DNS_TXT"
	  }))> | default: []
  	 edgerc_path  = <string> | default: "~/.edgerc"
  	 enable_validation  = <bool> | default: false
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_akamai"></a> [akamai](#requirement\_akamai) | ~> 10.0 |

## Resources

| Name | Type |
|------|------|
| [local_file.dom_challenges](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.dom_search_results](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.validation_entries](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_dom_validation"></a> [dom\_validation](#module\_dom\_validation) | git::ssh://git@github.com/akamai/terraform-templates-modules.git//dom | v2.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_edgerc_section"></a> [edgerc\_section](#input\_edgerc\_section) | Section in the .edgerc file | `string` | n/a | yes |
| <a name="input_domain_search_entries"></a> [domain\_search\_entries](#input\_domain\_search\_entries) | List of domains to search validation status for, independent of domain\_validation\_entries | <pre>list(object({<br/>    domain_name      = string<br/>    validation_scope = string<br/>  }))</pre> | `[]` | no |
| <a name="input_domain_validation_entries"></a> [domain\_validation\_entries](#input\_domain\_validation\_entries) | A list of objects with hostnames, domains, or wildcards to DOM validate | <pre>list(object({<br/>    domain_name      = string<br/>    validation_scope = string<br/>    validation_method = optional(string, "DNS_TXT")  # Default to "DNS_TXT"<br/>  }))</pre> | `[]` | no |
| <a name="input_edgerc_path"></a> [edgerc\_path](#input\_edgerc\_path) | Path to the .edgerc file | `string` | `"~/.edgerc"` | no |
| <a name="input_enable_validation"></a> [enable\_validation](#input\_enable\_validation) | Set to true to enable domain validation | `bool` | `false` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
