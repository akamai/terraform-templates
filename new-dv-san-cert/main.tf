/**
 * # Akamai DV SAN Certificate Enrollment Module
 * 
 * This Terraform module automates the creation and management of **Akamai Certificate Provisioning System (CPS)** enrollments for **Domain Validated (DV)** certificates with **Subject Alternative Names (SANs)**.
 * 
 * The module supports configuration of administrative and technical contacts, CSR generation, network and TLS configurations, After creation, the module automatically outputs DNS and HTTP challenge details into [dns-challenges.txt] and [http-challenges.txt]
 * 
 * ## Prerequisites
 * 
 * - Terraform v1.4+  
 * - Akamai Terraform Provider installed  
 * - Access to an Akamai account with CPS permissions  
 * - `.edgerc` file configured with proper credentials
 * - **Recommendation**: Use a dedicated .edgerc section per account for clean separation.
 * 
 * ## Project Structure
 * 
 * ├── provider.tf
 * ├── main.tf
 * ├── variables.tf
 * ├── terraform.tfvars
 * ├── files.tf
 * └── dns-challenges.txt / http-challenges.txt
 * 
 * ### File Overview
 * 
 * | File | Description |
 * |------|--------------|
 * | **main.tf** | Core Terraform logic for Akamai CPS enrollment and configuration. |
 * | **variables.tf** | Declares all configurable variables with types and descriptions. |
 * | **terraform.tfvars** | Example values for user configuration (to be customized). |
 * | **files.tf** | Writes DNS and HTTP challenge details to local text files for validation. |
 * | **dns-challenges.txt** | contains DNS validation records (CNAME or TXT values),Generated at root after apply
 * | **http-challenges.txt** |contains HTTP validation tokens and paths,Generated at root after apply
 * 
 * **Usage**
 * - Update your terraform.tfvars with project-specific values.
 * - Initialize Terraform: **terraform init**
 * - Review the plan: **terraform plan**
 * - Apply the configuration: **terraform apply**
 * - After successful execution, check the root folder for **dns-challenges.txt** and **http-challenges.txt**
 * 
 * **Output artifacts**
 * - After successful enrollment creation in CPS, two files will be written at the root:
 *     [dns-challenges.txt] → contains all DNS-based validation records
 *     [http-challenges.txt] → contains all HTTP-based validation details
 * 
 * - Each file includes the domain, path (or CNAME), and target value to be configured for CPS validation.
 * 
 * - Files are created at the root path (where Terraform is executed) and not inside the module.This separation ensures output visibility and avoids overwriting module files.
 * 
 * **terraform.tfvars**
 * - This file defines all input variables used by the DV SAN Certificate module.
 * Update the placeholders (<...>) with actual customer or project-specific values before running Terraform.
 * 
 * ## Note
 * 
 * - Set [acknowledge_pre_verification_warnings] = [true] only after confirming CPS warnings are acceptable.
 * 
 * - If you don’t set this flag to true, Terraform will fail the run with a error message such as **Enrollment cannot proceed until you acknowledge pre-verification warnings**
 * 
 * - Only set it to false if you want to manually review and accept warnings through the Akamai Control Center UI before proceeding.
 * 
 * - [sni_only] = set it to [true] or [false] depending on the requirement.
*/


module "dv-san-cert" {
  source = "git::ssh://git@github.com/akamai/terraform-templates-modules.git//dv-san-cert?ref=v1.3.3"

  common_name                           = var.common_name
  allow_duplicate_common_name           = var.allow_duplicate_common_name
  sans                                  = var.sans
  secure_network                        = var.secure_network
  sni_only                              = var.sni_only
  acknowledge_pre_verification_warnings = var.acknowledge_pre_verification_warnings

  admin_contact = {
    first_name       = var.admin_contact.first_name
    last_name        = var.admin_contact.last_name
    organization     = var.admin_contact.organization
    email            = var.admin_contact.email
    phone            = var.admin_contact.phone
    address_line_one = var.admin_contact.address_line_one
    city             = var.admin_contact.city
    region           = var.admin_contact.region
    postal_code      = var.admin_contact.postal_code
    country_code     = var.admin_contact.country_code
  }

  certificate_chain_type = var.certificate_chain_type

  csr = {
    country_code        = var.csr.country_code
    city                = var.csr.city
    organization        = var.csr.organization
    organizational_unit = var.csr.organizational_unit
    state               = var.csr.state
  }

  network_configuration = {
    disallowed_tls_versions = var.network_configuration.disallowed_tls_versions
    clone_dns_names         = var.network_configuration.clone_dns_names
    geography               = var.network_configuration.geography
    must_have_ciphers       = var.network_configuration.must_have_ciphers
    ocsp_stapling           = var.network_configuration.ocsp_stapling
    preferred_ciphers       = var.network_configuration.preferred_ciphers
  }

  signature_algorithm = var.signature_algorithm

  tech_contact = {
    first_name       = var.tech_contact.first_name
    last_name        = var.tech_contact.last_name
    organization     = var.tech_contact.organization
    email            = var.tech_contact.email
    phone            = var.tech_contact.phone
    address_line_one = var.tech_contact.address_line_one
    city             = var.tech_contact.city
    region           = var.tech_contact.region
    postal_code      = var.tech_contact.postal_code
    country_code     = var.tech_contact.country_code
  }

  organization = {
    name             = var.organization.name
    phone            = var.organization.phone
    address_line_one = var.organization.address_line_one
    address_line_two = var.organization.address_line_two
    city             = var.organization.city
    region           = var.organization.region
    postal_code      = var.organization.postal_code
    country_code     = var.organization.country_code
  }

  contract_id = var.contract_id

}