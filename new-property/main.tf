/**
 * # Onboarding: Akamai Property
 *
 * ## Authentication
 *
 * Please refer to [Terraform Overview](https://techdocs.akamai.com/terraform/docs/overview) and [Terraform Alternative authentication](https://techdocs.akamai.com/terraform/docs/gs-authentication) for more details on how to authenticate to Akamai when using Terraform.
 * 
 * ## Usage Instructions
 *  Akamai Terraform Deployment Guide
 *  This guide will help you onboard hostnames using Akamai Terraform templates for:
 *      DSA, IOn and ION Premier: new-property
 *
 *  ### Step 1: Download the Templates
 *  Clone the repository, using following command:
 * 
 *  ```bash
 *  > git clone <git url>
 *  > cd terraform-templates/new-property/
 *  ```
 *
 *  ### Step 2: Update `terraform.tfvars`
 *  Update the `terraform.tfvars` file with the required details:
 *
 *  #### Account Section as mentioned in the .edgerc file
 *  `edgerc_section = "<Account Section Name>"`
 *
 *  Powershell command : `Get-AccountSwitchKey 'Account Name'`
 *
 *  #### Name of the Configuration
 *  `name           = "<Config Name>"`
 *
 *  #### Contract and Group Details
 *  `contract_id    = "<Contract ID>"`
 *
 *  Powershell command : `Get-Contract -Section "edgercsection-name"`
 *
 *  `group_id       = "<Group ID>"`
 *  Powershell command : `Get-Group -Section "edgercsection-name"`
 *
 *  #### Hostnames you wish to onboard
 *  `hostnames      = ["<hostname1>", "<hostname2>"]`
 *
 *  #### Origin Details
 *  `default_origin = "<Origin Name>"`
 *
 *  #### Notification Email
 *  `email          = "<Your Email ID>"`
 *
 *  #### TLS Settings
 *  ```
 *  etls   = true  # Set to true for Enhanced TLS
 *  certificate_id = "<Certificate ID>"
 *  ```
 *  Powershell command : `Get-CPSEnrollment -Section 'edgercsection-name'`. "id" will be the Certificate ID.
 *
 *  #### Secure by Default Settings
 *  `secure_by_default = false  # Set to true for SBD cert`
 *
 *  If `secure_by_default` is true, comment the certificate_id as SBD doesn't need one.
 *
 *  **Note:**
 *  If you want to create a Secure by Default (SBD) certificate:
 *     1. Set `secure_by_default = true`
 *     2. Ensure `enhanced_tls` is also set to `true` if you want edgekey.net EHN
 *     3. Comment the `certificate_id` as SBD does not require one.
 *
 *  ### Step 3: Run Terraform
 *  Run the deployment script `../deploy.ps1`. This script is written in PowerShell and acts as an orchestrator for Terraform. It allows to perform individual save and activation actions, it handles the multi-environment directory and files to avoid overwriting the state file. A debug/log mode can also be enabled.
 *
 * A common flow is as follows (with "prod" as the environment):
 * 1. Save the changes only (no activations) using the PM template/product:
 * ```bash
 * PS> .\deploy.ps1 pm -Env prod -Save -Notes "Some user notes"
 * ```
 *
 * 2. Activate to staging:
 * ```bash
 * PS> .\deploy.ps1 pm -Env prod -ActivateStaging
 * ```
 *
 * 3. Activate to production:
 * ```bash
 * PS> .\deploy.ps1 pm -Env prod -ActivateProduction
 * ```
 *     
 * Options:
 * * Add the `-Debug` option to the command to log all the Terraform actions in a file stored in the specific environment directory.
 * * Add the `-Dry` option to the command to do a dry-run (nothing is applied).
 * * You can delete all the resources when you don't need them. Keep in mind some resource can't be deleted in which cases the `terraform destroy` operation will fail as a consequence.
 *     ```bash
 *     PS> .\deploy.ps1 pm -Env dev -Destroy
 *     ```
 */


module "property" {
  source = "git::https://github.com/akamai/terraform-templates-modules.git//delivery?ref=v1.5.0"

  contract_id = var.contract_id
  group_id    = var.group_id


  product_id             = var.product_id
  name                   = var.name
  version_notes          = var.version_notes
  hostnames              = var.hostnames
  etls                   = var.etls
  default_origin         = var.default_origin
  forward_host_header    = var.forward_host_header
  additional_origins     = var.additional_origins
  sure_route_test_object = var.sure_route_test_object
  td_region              = var.td_region
  enable_mPulse          = var.enable_mPulse

  notification_emails             = var.emails
  activate_to_staging             = var.activate_to_staging
  activate_to_production          = var.activate_to_production
  noncompliance_reason            = var.noncompliance_reason
  ticket_id                       = var.ticket_id
  other_noncompliance_reason      = var.other_noncompliance_reason
  peer_reviewed_by                = var.peer_reviewed_by
  customer_email                  = var.customer_email
  unit_tested                     = var.unit_tested
  activation_notes                = var.activation_notes
  activation_to_staging_exists    = var.activation_to_staging_exists
  activation_to_production_exists = var.activation_to_production_exists

  default_cpcode = var.default_cpcode
  cpcode_name    = var.cpcode_name

  secure_by_default = var.secure_by_default
  certificate_id    = var.certificate_id

  ehn_domain  = var.ehn_domain
  ip_behavior = var.ip_behavior

  providers = {
    akamai = akamai
  }
}