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
 *  .\deploy.ps1 dom -Destroy
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
 * ## Generated Output Files
 *
 * A successful `dom -Run` operation creates the following files in the template directory and also prints the same information in the terminal output:
 * - `dom_challenges.txt` — TXT and CNAME validation challenge values to publish in DNS
 * - `dom_validation_entries.txt` — the configured validation entries with scope and method
 * - `dom_search_results.txt` — the domain search results returned by the DOM API
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
 *             domain_name      = "tflab.com"
 *             validation_scope = "DOMAIN"
 *         },
 *          {
 *             domain_name      = "*.tfdom.com"
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
 *   6. validation_method must be one of: DNS_TXT, DNS_CNAME, HTTP; HTTP is only valid for HOST entries 
 *
 *   ## Prerequisites
 *
 *   Before you start, make sure you have:
 * * [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.9.0
 * * [PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell) 7+ to run the deployment script  
 * * Akamai Provider >= 10.0
 * * Akamai API credentials (typically in `~/.edgerc`) with read-write access to Domain Ownership Manager
 *
 *   
 *  
 */



module "dom_validation" {
  source = "git::https://github.com/akamai/terraform-templates-modules.git//dom?ref=v2.0.4"
  
  domain_validation_entries = var.domain_validation_entries
  enable_validation         = var.enable_validation
  domain_search_entries     = var.domain_search_entries
}
