/**
 * # Onboarding: Akamai Adaptive Media Delivery (AMD) Property
 *
 * ## Authentication
 *
 * Please refer to [Terraform Overview](https://techdocs.akamai.com/terraform/docs/overview) and [Terraform Alternative authentication](https://techdocs.akamai.com/terraform/docs/gs-authentication) for more details on how to authenticate to Akamai when using Terraform.
 *
 * ## Usage Instructions
 *  Akamai Terraform Deployment Guide
 *  This guide will help you onboard hostnames using Akamai Terraform templates for:
 *      Adaptive Media Delivery (AMD): new-property-media
 *
 *  ### Step 1: Download the Templates
 *  Clone the repository, using following command:
 *
 *  ```bash
 *  > git clone <git url>
 *  > cd terraform-templates/new-property-media/
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
 *
 *  Powershell command : `Get-Group -Section "edgercsection-name"`
 *
 *  #### Hostnames you wish to onboard
 *  `hostnames      = ["<hostname1>", "<hostname2>"]`
 *
 *  #### Origin Details
 *  `default_origin = "<Origin Name>"`
 *
 *  #### Notification Email
 *  `emails         = ["<Your Email ID>"]`
 *
 * Select the edge-hostname mode and matching TLS settings:
 *
 * - `SBD`: `etls=true` uses edgekey.net; `etls=false` uses edgesuite.net.
 * - `EDGESUITE`: Standard TLS; requires `etls=false`.
 * - `EDGEKEY`: Enhanced TLS; requires `etls=true` and `certificate_id`.
 * - `AKAMAIZED_HOSTNAME`: Shared certificate; provide only the hostname label. The pre-activation Domain Ownership check is skipped for this mode.
 *
 *  #### AMD-specific behaviors
 *  Set `segmented_media_optimization_behavior` to `LIVE` for live streams or `ON_DEMAND` for video on demand.
 *  Use `additional_origins` for hostname- or path-based origin routing.
 *
 *  ### Step 3: Run Terraform
 *  Run the deployment script `../deploy.ps1`. This script is written in PowerShell and acts as an orchestrator for Terraform. It allows to perform individual save and activation actions, it handles the multi-environment directory and files to avoid overwriting the state file. A debug/log mode can also be enabled.
 *
 * A common flow is as follows (with "prod" as the environment):
 * 1. Save the changes only (no activations) using the pm-media template:
 * ```bash
 * PS> .\deploy.ps1 pm-media -Env prod -Save -Notes "Some user notes"
 * ```
 *
 * 2. Activate to staging:
 * ```bash
 * PS> .\deploy.ps1 pm-media -Env prod -ActivateStaging
 * ```
 *
 * 3. Activate to production:
 * ```bash
 * PS> .\deploy.ps1 pm-media -Env prod -ActivateProduction
 * ```
 *
 * Options:
 * * Add the `-Debug` option to the command to log all the Terraform actions in a file stored in the specific environment directory.
 * * Add the `-Dry` option to the command to do a dry-run (nothing is applied).
 * * You can delete all the resources when you don't need them. Keep in mind some resource can't be deleted in which cases the `terraform destroy` operation will fail as a consequence.
 *     ```bash
 *     PS> .\deploy.ps1 pm-media -Env dev -Destroy
 *     ```
 */

module "property" {
  source = "git::https://github.com/akamai/terraform-templates-modules.git//delivery-media?ref=v2.1.0"

  contract_id   = var.contract_id
  group_id      = var.group_id
  product_id    = var.product_id
  name          = var.name
  version_notes = var.version_notes

  hostnames           = var.hostnames
  edge_hostname_type  = var.edge_hostname_type
  certificate_id      = var.certificate_id
  ip_behavior         = var.ip_behavior
  etls                = var.etls
  default_origin      = var.default_origin
  additional_origins  = var.additional_origins
  forward_host_header = var.forward_host_header
  http2_enabled       = var.http2_enabled
  min_tls_version     = var.min_tls_version
  verification_mode   = var.verification_mode

  segmented_media_optimization_behavior = var.segmented_media_optimization_behavior
  origin_authentication_method          = var.origin_authentication_method
  origin_country                        = var.origin_country
  client_country                        = var.client_country

  content_catalog_size            = var.content_catalog_size
  content_type                    = var.content_type
  content_popularity_distribution = var.content_popularity_distribution
  enable_dash                     = var.enable_dash
  enable_hds                      = var.enable_hds
  enable_hls                      = var.enable_hls
  enable_smooth                   = var.enable_smooth
  segment_duration_dash           = var.segment_duration_dash
  segment_duration_hds            = var.segment_duration_hds
  segment_duration_hls            = var.segment_duration_hls
  segment_duration_smooth         = var.segment_duration_smooth

  cache_key_query_params_behavior        = var.cache_key_query_params_behavior
  enable_dynamic_throughput_optimization = var.enable_dynamic_throughput_optimization
  enable_http3                           = var.enable_http3

  enable_segmented_content_protection = var.enable_segmented_content_protection
  dash_media_encryption               = var.dash_media_encryption
  hls_media_encryption                = var.hls_media_encryption

  enable_debug = var.enable_debug
  debug_key    = var.debug_key

  activation_contacts             = var.emails
  activate_to_staging             = var.activate_to_staging
  activate_to_production          = var.activate_to_production
  activation_to_staging_exists    = var.activation_to_staging_exists
  activation_to_production_exists = var.activation_to_production_exists
  noncompliance_reason            = var.noncompliance_reason
  ticket_id                       = var.ticket_id
  other_noncompliance_reason      = var.other_noncompliance_reason
  peer_reviewed_by                = var.peer_reviewed_by
  customer_email                  = var.customer_email
  unit_tested                     = var.unit_tested
  activation_notes                = var.activation_notes

  cpcode_name = var.cpcode_name

  providers = {
    akamai = akamai
  }
}
