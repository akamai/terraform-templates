/**
 * # Akamai CPS Third-Party Certificate Module
 * 
 * This Terraform configuration manages Akamai Certificate Provisioning System (CPS) third-party certificate enrollments. Handles both enrollment (creating a new certificate request) and certificate upload.
 * It supports:
 * 
 * ## Two-phase workflow in Terraform when dealing with Third-Party signed certificates:
 * 
 * ### Phase 1 → Terraform creates the enrollment + CSR.
 * - Creating an enrollment with certificate details (SANs, contacts, CSR, network config, etc.)
 * - You take the CSR, submit to a CA, and later come back with the signed cert.
 * 
 * ### Phase 2 → Terraform uploads the signed certificate to Akamai.
 * - Uploading RSA or ECDSA certificates and their trust chains in pem format 
 * 
 * ## Prerequisites
 * 
 * - Terraform v1.9+
 * - Akamai Terraform Provider
 * - An Akamai .edgerc file with valid credentials
 * 
 * ## Project Structure
 * ```
 * .
 * ├── main.tf               # Root module calling the CPS enrollment module
 * ├── variables.tf          # Input variables definition
 * ├── terraform.tfvars      # User-supplied variable values
 * ├── files.tf              # Generates CSR files for ECDSA and RSA certificates  
 * ├── providers.tf          # Akamai provider configuration
 * ├── csr_ecdsa.pem         # Generated ECDSA CSR (auto-generated)
 * └── csr_rsa.pem           # Generated RSA CSR (auto-generated)
 * ```
 * 
 * ## Scenario 1: Create a New Enrollment
 * 
 * If you are creating certificate for the first time, you will create an enrollment with your domain details with the help of tfvars. 
 * 
 * ## Scenario 2: Upload a Certificate to an Existing Enrollment
 * 
 * Once an enrollment exists/created, you can upload your RSA/ ECDSA cert and trust chain.
 * ```hcl
 * enrollment_id = 12345
 * 
 * certificate_rsa_pem   = file("rsa_certificate.pem")
 * trust_chain_rsa_pem   = file("rsa_certificate_ca.pem")
 * certificate_ecdsa_pem = ""
 * trust_chain_ecdsa_pem = ""
 * ````
 * - This attaches your certificate to the given enrollment and deploys it to the Akamai edge.
 * 
 * **Please note**
 * 
 * 1. `change_management`
 *     1. Purpose: Enables Akamai Change Management workflow (review/approve before deployment).
 *     2. If `true` changes are put into Change Management pending state until manually approved.
 *     3. If `false`  changes go straight through without requiring Change Management approval.     
 * 
 * 2. `acknowledge_post_verification_warnings`
 *     1. Purpose: After CPS runs verification (DNS checks, certificate validation, etc.), it may raise warnings.
 *     2. If `true`: it indicates that you acknowledge the post-verification warnings and confirm proceeding with the deployment
 *     3. If `false`: deployment halts until warnings are reviewed/cleared.
 * 
 * 3. If only one type (RSA or ECDSA) is used, leave the other’s fields blank.
*/

module "third-party-cert" {
  source = "git::https://github.com/akamai/terraform-templates-modules.git//third-party-cert?ref=v1.3.3"

  //enrollment_id                        = var.enrollment_id
  common_name                           = var.common_name
  allow_duplicate_common_name           = var.allow_duplicate_common_name
  sans                                  = var.sans
  secure_network                        = var.secure_network
  sni_only                              = var.sni_only
  acknowledge_pre_verification_warnings = var.acknowledge_pre_verification_warnings
  auto_approve_warnings                 = var.auto_approve_warnings

  admin_contact = {
    first_name       = var.admin_contact.first_name
    last_name        = var.admin_contact.last_name
    organization     = var.admin_contact.organization
    email            = var.admin_contact.email
    phone            = var.admin_contact.phone
    address_line_one = var.admin_contact.address_line_one
    address_line_two = var.admin_contact.address_line_two
    city             = var.admin_contact.city
    region           = var.admin_contact.region
    postal_code      = var.admin_contact.postal_code
    country_code     = var.admin_contact.country_code
  }

  //certificate_chain_type = var.certificate_chain_type

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
    quic_enabled            = var.network_configuration.quic_enabled
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

  contract_id       = var.contract_id
  change_management = var.change_management

  # ------------------------
  # CPS Upload Certificate
  # ------------------------

  // enrollment_id                          = var.enrollment_id
  certificate_ecdsa_pem                  = var.certificate_ecdsa_pem
  certificate_rsa_pem                    = var.certificate_rsa_pem
  trust_chain_ecdsa_pem                  = var.trust_chain_ecdsa_pem
  trust_chain_rsa_pem                    = var.trust_chain_rsa_pem
  acknowledge_post_verification_warnings = var.acknowledge_post_verification_warnings
  // auto_approve_warnings                  = var.auto_approve_warnings
  acknowledge_change_management = var.acknowledge_change_management
  wait_for_deployment           = var.wait_for_deployment
}