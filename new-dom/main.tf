/**
 * # Akamai Domain Ownership Management (DOM)
 *
 * This Terraform configuration manages Akamai Domain Ownership validation for your properties.
 *
 *
 * ## Overview
 *
 * Prove ownership of new domains you onboard to Akamai before activating your property configuration. This prevents unauthorized use of hostnames on the Akamai network, which improves overall security.
 *
 * There is a standard schedule of DOM background jobs (crons) and validates the domain straight away or after a short delay. You can use the `akamai_property_domainownership_validation` resource to validate your domains immediately.
 * 
 * ## Workflow
 *
 * ## Step 1: Create Domain Ownership Records
 *
 * Run Terraform in this directory to create the domain ownership records:
 *
 *  ```
 *  
 *  .\deploy.ps1 dom -Run -Dry 
 *  .\deploy.ps1 dom -Run 
 *  ```
 *
 * This creates the necessary records in Akamai and outputs the TXT record values you need to add to your DNS.
 *
 *
 * ## Step 2: Configure DNS Records
 *
 * Add the TXT or CNAME records from the Terraform output to your DNS provider. Wait for DNS propagation.
 *
 * 
 * ## Step 3: Validate Domains
 *
 * After DNS records are in place, and you want to force a validation:
 *
 * In the `terraform.tfvars` file update the `enable_validation = true`
 *
 *  This triggers immediate validation of your domains instead of waiting for the background validation jobs.
 *
 *
 * ## Configuration
 *
 * ## Domain Validation Entries
 *
 * Configure your domains in `terraform.tfvars`:
 *
 * ```
 *  	     domain_validation_entries = [
 *          {
 *             domain_name      = "host.example.com"
 *             validation_scope = "HOST"
 *          },
 *          {
 *             domain_name      = "example.com"
 *             validation_scope = "DOMAIN"
 *         },
 *          {
 *             domain_name      = "*.example.com"
 *             validation_scope = "WILDCARD"
 *          }
 *        ]
 * ```
 *
 * ## Validation Scopes
 *
 *   1. **HOST**: Use for exact domains. For example, blog.example.com validates only that specific hostname.
 *   2. **WILDCARD**: Use for first-level subdomains. For example, *.example.com validates blog.example.com and 123.example.com, but not xyz.blog.example.com or the apex example.com.
 *   3. **DOMAIN**: Use for exact domains and all subdomains. For example, example.com validates blog.example.com, 123.blog.example.com, x.123.blog.example.com, and the apex domain.
 *
 *
 * ## Validation Rules
 *
 *   1. Maximum of 1000 domain validation entries
 *   2. Validation scope must be HOST, DOMAIN, or WILDCARD (case-insensitive)
 *   3. HOST entries cannot overlap with DOMAIN entries (e.g., host.example.com conflicts with example.com)
 *   4. WILDCARD entries must start with *. and contain a valid base domain
 *   5. HOST and DOMAIN entries cannot use wildcard prefix
 *
 *
 *   ## Requirements
 *  
 *   ```
 *   Terraform >= 1.9.0
  *   Akamai Provider >= 10.0
 *   ```
 *
 *   ## Akamai API Credentials
 *   
 *   The Akamai API user configured in your Terraform credentials must have the following access level:
 *
 *   ```
 *   API Service: Domain Ownership Manager
 *   Access Level: READ-WRITE
 *   ```
 *
 *   Configure this in your Akamai control panel when setting up API credentials. Ensure your .edgerc file references the correct section with these permissions.
 */



module "dom_validation" {
  source = "git::https://github.com/akamai/terraform-templates-modules.git//dom?ref=v2.0.0"

  domain_validation_entries = [
    for entry in var.domain_validation_entries : {
      domain_name       = entry.domain_name
      validation_scope  = upper(entry.validation_scope)
      validation_method = entry.validation_method
    }
  ]
  enable_validation     = var.enable_validation
  edgerc_path           = var.edgerc_path
  edgerc_section        = var.edgerc_section
  domain_search_entries = var.domain_search_entries
}
