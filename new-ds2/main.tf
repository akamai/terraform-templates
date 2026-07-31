/**
 * # Onboarding: Akamai DataStream 2 (DS-managed / Decoupled)
 *
 * This template provisions a **DataStream 2 (DS2)** configuration using the
 * decoupled ("DS-managed") workflow. It collects delivery logs for existing
 * Akamai properties **without** requiring any DataStream behavior in the
 * Property Manager rule tree.
 *
 * Existing properties are associated via `property_ids` — the stream runs in
 * `DS_MANAGED` mode and begins delivering logs when those properties are active.
 *
 * ## Authentication
 *
 * Please refer to [Terraform Overview](https://techdocs.akamai.com/terraform/docs/overview)
 * and [Terraform Alternative authentication](https://techdocs.akamai.com/terraform/docs/gs-authentication)
 * for details on how to authenticate to Akamai when using Terraform.
 *
 * Authentication is provided via a `.edgerc` file and the `edgerc_section`
 * variable.
 *
 * ## Usage Instructions
 *
 * ### Step 1: Download the Templates
 * Clone the repository, using the following command:
 *
 * ```bash
 * > git clone <git url>
 * > cd terraform-templates/new-ds2/
 * ```
 *
 * ### Step 2: Update the environment `.tfvars`
 * Copy the `.tfvars.dist` file for your environment (for example
 * `environments/dev/dev.tfvars.dist`), remove the `.dist` extension, and fill in:
 *
 * - `edgerc_section` — account section in your `.edgerc` file
 * - `contract_id` / `group_id` — target contract and group
 * - `name` — the DataStream name
 * - `property_ids` — the Akamai property IDs to monitor
 * - Exactly **one** connector block (S3, Datadog, Splunk, HTTPS, etc.)
 *
 * ### Step 3: Run Terraform
 * Run the deployment script `../deploy.ps1`. This script acts as an orchestrator
 * for Terraform, handling multi-environment state isolation and save/activate
 * actions.
 *
 * ## Connectors
 *
 * Exactly **one** connector must be configured. Supported destinations:
 *
 * - AWS S3 (`s3_connector`)
 * - S3-Compatible — MinIO, Wasabi, Cloudflare R2 (`s3_compatible_connector`)
 * - Azure Blob Storage (`azure_connector`)
 * - Google Cloud Storage (`gcs_connector`)
 * - Oracle Cloud Object Storage (`oracle_connector`)
 * - Datadog (`datadog_connector`)
 * - Splunk (`splunk_connector`)
 * - Custom HTTPS (`https_connector`)
 * - Sumo Logic (`sumologic_connector`)
 * - Loggly (`loggly_connector`)
 * - New Relic (`new_relic_connector`)
 * - Elasticsearch (`elasticsearch_connector`)
 * - Dynatrace (`dynatrace_connector`)
 * - TrafficPeak / Hydrolix (`trafficpeak_connector`)
 */
module "ds2" {
  source = "git::ssh://git@github.com/akamai/terraform-templates-modules.git//ds2?ref=v2.0.1"

  # Scope
  name         = var.name
  contract_id  = var.contract_id
  group_id     = var.group_id
  property_ids = var.property_ids

  # Stream behaviour
  activate_stream     = var.activate_stream
  notification_emails = var.notification_emails
  enable_midgress     = var.enable_midgress
  dataset_fields_ids  = var.dataset_fields_ids
  sampling_percentage = var.sampling_percentage
  log_format          = var.log_format
  field_delimiter     = var.field_delimiter
  interval_in_secs    = var.interval_in_secs
  upload_file_prefix  = var.upload_file_prefix
  upload_file_suffix  = var.upload_file_suffix

  # Connectors (configure exactly one)
  s3_connector            = var.s3_connector
  s3_compatible_connector = var.s3_compatible_connector
  azure_connector         = var.azure_connector
  gcs_connector           = var.gcs_connector
  oracle_connector        = var.oracle_connector
  datadog_connector       = var.datadog_connector
  splunk_connector        = var.splunk_connector
  https_connector         = var.https_connector
  sumologic_connector     = var.sumologic_connector
  loggly_connector        = var.loggly_connector
  new_relic_connector     = var.new_relic_connector
  elasticsearch_connector = var.elasticsearch_connector
  dynatrace_connector     = var.dynatrace_connector
  trafficpeak_connector   = var.trafficpeak_connector
}
