/**
 * # Module: new-edns (Akamai Edge DNS)
 *
 * This module provisions and manages **Akamai Edge DNS (EDNS)** zones using Terraform.
 * It supports both **PRIMARY** and **SECONDARY** DNS zones and provides full lifecycle
 * management of DNS records for PRIMARY zones.
 *
 * The module is designed to be consumed by higher-level templates
 * (for example: ps-terraform-templates) and follows the same documentation
 * and automation standards as other official PS Terraform modules.
 *
 * ---
 *
 * ## Authentication
 *
 * This module uses **Akamai EdgeGrid authentication**.
 *
 * Please refer to:
 * [DevOps Harmony / Setting up OpenAPI/EdgeGrid for PS]
 * (https://collaborate.akamai.com/confluence/pages/viewpage.action?pageId=748278616)
 *
 * Authentication details are provided via:
 * - `.edgerc` file
 * - `edgerc_section` variable
 *
 * ---
 *
 * ## Supported Zone Types
 *
 * ### PRIMARY
 * - Creates a new authoritative DNS zone in Akamai Edge DNS
 * - Allows full management of DNS records
 * - Optional SOA record management
 * - Automatically retrieves Akamai authoritative nameservers
 *
 * ### SECONDARY
 * - Creates a secondary (slave) DNS zone
 * - Requires master server IPs (`masters`)
 * - Optional TSIG configuration for zone transfers
 * - DNS records are **not managed** (replicated from the master)
 *
 * ---
 *
 * ## Managed Resources
 *
 * - `akamai_dns_zone`
 * - `akamai_dns_record` (multiple types, PRIMARY only)
 * - `akamai_authorities_set` (authoritative NS discovery)
 * - `time_sleep` (SOA propagation wait)
 *
 * ---
 *
 * ## Usage
 *
 * Basic usage of this module:
 *
 * ```hcl
 * module "edns" {
 *   source = "git::ssh://git@git.source.akamai.com:7999/gss-devops/ps-terraform-templates-modules.git//new-edns?ref=vX.Y.Z"
 *
 *   contract_id = "ctr_XXXX"
 *   group_id    = "grp_XXXX"
 *
 *   zone_name = "example.com"
 *   zone_type = "primary"
 * }
 * ```
 *
 * ---
 *
 * ## PRIMARY Zone – DNS Records
 *
 * When `zone_type = "primary"`, DNS records can be managed by uncommenting
 * and populating the corresponding variables in `terraform.tfvars`.
 *
 * Supported record types include:
 *
 * - A
 * - AAAA
 * - CNAME
 * - TXT
 * - NS
 * - MX
 * - SRV
 * - CAA
 * - PTR
 * - LOC
 * - SPF
 * - RP
 *
 * Each record type is defined as a list of objects.
 * If a list is empty, no records of that type are created.
 *
 * ---
 *
 * ## SOA Management (PRIMARY only)
 *
 * SOA record management is optional.
 *
 * - If `soa = null` → SOA is not managed by Terraform
 * - If `soa` is provided → SOA is explicitly created/updated
 *
 * The module also reads back the SOA record after zone creation
 * and exposes both raw and parsed values as outputs.
 *
 * ---
 *
 * ## SECONDARY Zone – Masters & TSIG
 *
 * For `zone_type = "secondary"`:
 *
 * - `masters` must contain at least one IP address
 * - Optional TSIG authentication can be configured using `tsig_key`
 *
 * DNS records are **not created** for secondary zones.
 *
 * ---
 *
 * ## Nameservers (NS)
 *
 * The module automatically retrieves the **Akamai authoritative nameservers**
 * assigned to the contract.
 *
 * Outputs include:
 * - Akamai authoritative NS (FQDNs)
 * - IPv4 addresses resolved for those NS
 *
 * These outputs can be used to:
 * - Configure delegation at a parent DNS provider
 * - Populate `masters` for SECONDARY zones
 * - Generate ready-to-paste tfvars snippets
 *
 * Custom NS records can also be provided explicitly via `ns_records`
 * (PRIMARY zones only).
 *
 * ---
 *
 * ## Outputs
 *
 * The module exposes outputs for:
 *
 * - Zone name and type
 * - Raw and parsed SOA (PRIMARY)
 * - Akamai authoritative nameservers
 * - Nameserver IPv4 addresses
 * - Configured SECONDARY masters
 *
 * ---
 */

## ----------------------------------------------------------------------------
# Provider: DNS (public lookups for NS → IP)
## ----------------------------------------------------------------------------
provider "dns" {}

## ----------------------------------------------------------------------------
# Module: New EdgeDNS (PRIMARY / SECONDARY)
## ----------------------------------------------------------------------------
module "edns" {
  source = "git::ssh://git@github.com/akamai/terraform-templates-modules.git//edns?ref=v2.0.0"

  zone_name   = var.zone_name
  zone_type   = var.zone_type
  contract_id = var.contract_id
  group_id    = var.group_id

  edgerc_path    = var.edgerc_path
  edgerc_section = var.edgerc_section

  masters  = var.masters
  tsig_key = var.tsig_key
  soa      = var.soa

  # NS and SOA MUST ALWAYS EXIST
  ns_records = var.destroy_mode ? [
    for ns in var.ns_records : ns if ns.name == "@"
  ] : var.ns_records


  # User-managed records (forced empty during destroy)
  a_records     = var.force_empty_records ? [] : var.a_records
  aaaa_records  = var.force_empty_records ? [] : var.aaaa_records
  cname_records = var.force_empty_records ? [] : var.cname_records
  txt_records   = var.force_empty_records ? [] : var.txt_records
  ptr_records   = var.force_empty_records ? [] : var.ptr_records
  loc_records   = var.force_empty_records ? [] : var.loc_records
  spf_records   = var.force_empty_records ? [] : var.spf_records
  rp_records    = var.force_empty_records ? [] : var.rp_records
  hinfo_records = var.force_empty_records ? [] : var.hinfo_records

  mx_records  = var.force_empty_records ? [] : var.mx_records
  srv_records = var.force_empty_records ? [] : var.srv_records
  caa_records = var.force_empty_records ? [] : var.caa_records
}


