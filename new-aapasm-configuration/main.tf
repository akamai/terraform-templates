/**
 * # Onboarding: App & API Protector (AAP) and the Advanced Security Management (ASM)
 *
 * This template creates a complete Akamai security configuration, consisting of:
 *
 * * **Client Lists** (optional) — IP block, geo block, ASN block and security bypass lists. You can also reuse existing lists by providing their IDs.
 * * **Security Configuration** — the container for all policies, plus the config-level resources (advanced settings, rate policies, client reputation profiles).
 * * **Security Policies** — one or **many** policies, each protecting its own hostnames with independently configurable protection actions (WAF, DoS, Client Reputation, Bot Manager).
 * * **Activation** — pushes the configuration to the Akamai staging and/or production networks.
 *
 * It supports multiple environments (e.g. dev, qa, prod) if required by the customer, and the initial configuration for BVM (Bot Visibility and Management) or BMS (Bot Management Standard).
 *
 * ## Prerequisites
 *
 * Before you start, make sure you have:
 *
 * * [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.9.0
 * * [PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell) 7+ to run the deployment script
 * * Akamai API credentials (typically in `~/.edgerc`) with read-write access to the Application Security, Client Lists and Bot Manager APIs
 * * The Akamai **group name** where the configuration will be created (visible in Akamai Control Center)
 * * The **hostnames** you want to protect — they must already exist in a delivery property on the same contract
 *
 * ## Authentication
 *
 * Please refer to [Terraform Overview](https://techdocs.akamai.com/terraform/docs/overview) and [Terraform Alternative authentication](https://techdocs.akamai.com/terraform/docs/gs-authentication) for more details on how to authenticate to Akamai when using Terraform.
 *
 * ## Usage
 *
 * ### Step 1 — Clone the repository
 *
 * ```bash
 * > git clone <git url>
 * > cd terraform-templates/new-aapasm-configuration/
 * ```
 *
 * ### Step 2 — Set up your environment(s)
 *
 * The `./environments` folder holds one subdirectory per environment (e.g. `dev`, `qa`, `prod`), each with its own `tfvars` file and Terraform state, so environments never overwrite each other.
 *
 * 1. Keep (or create) one subdirectory per environment you need. If you only need a single environment, keep just one directory (you can name it "prod") and delete the others.
 * 2. The `tfvars` filename must be prefixed with the environment name: for "prod" the file is `prod.tfvars`.
 * 3. Rename the example file by removing the `.dist` extension (e.g. `prod.tfvars.dist` → `prod.tfvars`) and fill in the required values. Each parameter is documented with inline instructions inside the file.
 *
 * ### Step 3 — Define your security policies
 *
 * This template supports **multiple security policies** in a single security configuration. In your `tfvars` file:
 *
 * 1. Set the baseline protection actions once in `policy_defaults`. These apply to every policy unless overridden.
 * 2. Define each policy in the `policies` map. A policy only needs `policy_name`, `policy_prefix` and `hostnames` — everything else is inherited from `policy_defaults`, and any field can be overridden per policy.
 *
 * ```hcl
 * policies = {
 *   main = {
 *     policy_name   = "main-website"
 *     policy_prefix = "MN01"                      # exactly 4 uppercase alphanumeric characters, unique per policy
 *     hostnames     = ["www.example.com"]
 *   }
 *   api = {
 *     policy_name    = "api-policy"
 *     policy_prefix  = "AP01"
 *     hostnames      = ["api.example.com"]
 *     waf_sql_action = "deny"                     # override: stricter WAF action for this policy only
 *     enable_botman  = false                      # override: no Bot Manager for this policy
 *   }
 * }
 * ```
 *
 * Keep in mind:
 *
 * * Map keys (`main`, `api`, ...) are stable identifiers — renaming a key destroys and recreates that policy.
 * * Hostnames must be lowercase and should not overlap between policies.
 * * The security configuration automatically covers the union of all policy hostnames.
 *
 * ### Step 4 — Deploy
 *
 * Run the deployment script `../deploy.ps1`. This script is written in PowerShell and acts as an orchestrator for Terraform. It performs the individual save and activation actions and handles the multi-environment directories and state files.
 *
 *     A common flow is as follows (with "prod" as the environment):
 *     1. Save the changes only (creates/updates the configuration without activating it):
 *     ```bash
 *     PS> .\deploy.ps1 aapasm -Env prod -Save -Notes "Some user notes"
 *     ```
 *
 *     2. Activate to staging (test against the Akamai staging network before going live):
 *     ```bash
 *     PS> .\deploy.ps1 aapasm -Env prod -ActivateStaging
 *     ```
 *
 *     3. Activate to production:
 *     ```bash
 *     PS> .\deploy.ps1 aapasm -Env prod -ActivateProduction
 *     ```
 *
 *     Options:
 *     * Add the `-Dry` option to any command to preview the changes without applying anything. Recommended for a first run.
 *     * Add the `-Debug` option to log all the Terraform actions in a file stored in the specific environment directory.
 *     * You can delete all the resources when you don't need them. Keep in mind some resources can't be deleted, in which case the `terraform destroy` operation will fail as a consequence.
 *     ```bash
 *     PS> .\deploy.ps1 aapasm -Env dev -Destroy
 *     ```
 *
 * ### Step 5 — Verify
 *
 * After a successful run, Terraform outputs the security configuration ID (`config_id`) and a map of policy keys to policy IDs (`security_policy_ids`). You can review the resulting configuration in Akamai Control Center under Security Configurations.
 *
 * ## Known Errors
 * ### Client Reputation
 * You may see the following error during the first terraform execution because Client Reputation may not be available/ready in time. A 20s delay has been added to allow for Client Reputation to become available. However in some occurrences it may take longer. Instead of waiting for longer we retry automatically the apply if the error happens.
 *
 * ```hcl
 * │ Error: Provider produced inconsistent final plan
 * │
 * │ When expanding the plan for module.security-policy["main"].akamai_appsec_reputation_profile_action.web_attackers_high_threat[0]
 * │ This is a bug in the provider, which should be reported in the provider's own issue tracker.
 * ```
 *
 * ### Destroy INTERNAL-SERVER-ERROR
 * This is probably the reason for another race condition with no further details. A retry happens automatically to overcome this error. The Destroy will succeed afterwards.
 *
 * ```hcl
 * │ Error: Title: Internal Server Error; Type: https://problems.luna.akamaiapis.net/appsec-configuration/error-types/INTERNAL-SERVER-ERROR; Detail: Error occurred while processing the request.
 * ```
 *
 */

data "akamai_contract" "contract" {
  group_name = var.group_name
}

# -------------------------------------------------
# Client Lists (optional, called once)
# -------------------------------------------------
module "client-lists" {
  count               = var.create_client_lists ? 1 : 0
  source              = "git::https://github.com/akamai/terraform-templates-modules.git//aap-asm/client-lists?ref=v2.0.0"
  client_lists_prefix = substr(var.config_name, 0, 20)
  config_name         = var.config_name
  contract_id         = trimprefix(data.akamai_contract.contract.id, "ctr_")
  group_id            = trimprefix(data.akamai_contract.contract.group_id, "grp_")
}

# -------------------------------------------------
# Resolve client list IDs (created vs user-provided)
# -------------------------------------------------
locals {
  client_lists_ipblock           = var.create_client_lists ? module.client-lists[0].client_lists_ipblock_id : var.client_lists_ipblock
  client_lists_ipblock_exception = var.create_client_lists ? module.client-lists[0].client_lists_ipblock_exception_id : var.client_lists_ipblock_exception
  client_lists_geoblock          = var.create_client_lists ? module.client-lists[0].client_lists_geoblock_id : var.client_lists_geoblock
  client_lists_asnblock          = var.create_client_lists ? module.client-lists[0].client_lists_asnblock_id : var.client_lists_asnblock
  client_lists_securitybypass    = var.create_client_lists ? module.client-lists[0].client_lists_securitybypass_id : var.client_lists_securitybypass
  client_lists_rcbypass          = var.create_client_lists ? module.client-lists[0].client_lists_rcbypass_id : var.client_lists_rcbypass
  client_lists_pragmabypass      = var.create_client_lists ? module.client-lists[0].client_lists_pragmabypass_id : var.client_lists_pragmabypass
}

# -------------------------------------------------
# Compute config-level hostnames (union of all policies)
# -------------------------------------------------
locals {
  all_hostnames = distinct(flatten([for p in var.policies : p.hostnames]))

  enable_client_reputation = anytrue([
    for key, policy in var.policies :
    policy.enable_client_reputation != null ? policy.enable_client_reputation : var.policy_defaults.enable_client_reputation
  ])
}

# -------------------------------------------------
# Security Config (singleton — called once)
# -------------------------------------------------
module "security-config" {
  source        = "git::https://github.com/akamai/terraform-templates-modules.git//aap-asm/security-config?ref=v2.0.0"
  contract_id   = trimprefix(data.akamai_contract.contract.id, "ctr_")
  group_name    = var.group_name
  config_name   = var.config_name
  description   = var.description
  hostnames     = local.all_hostnames
  version_notes = var.version_notes

  # Advanced Settings
  inspection_size = var.inspection_size

  # Bypass Lists
  client_lists_rcbypass       = local.client_lists_rcbypass
  client_lists_pragmabypass   = local.client_lists_pragmabypass
  client_lists_securitybypass = local.client_lists_securitybypass

  # Client Reputation
  enable_client_reputation = local.enable_client_reputation
}

# -------------------------------------------------
# Merge policy_defaults + per-policy overrides
# Using != null ternary (NOT coalesce — coalesce treats false/"" as empty)
# -------------------------------------------------
locals {
  resolved_policies = {
    for key, policy in var.policies : key => {
      policy_name   = policy.policy_name
      policy_prefix = policy.policy_prefix
      hostnames     = policy.hostnames

      # Protection Toggles
      enable_waf                 = policy.enable_waf != null ? policy.enable_waf : var.policy_defaults.enable_waf
      enable_request_constraints = policy.enable_request_constraints != null ? policy.enable_request_constraints : var.policy_defaults.enable_request_constraints
      enable_ip_geo              = policy.enable_ip_geo != null ? policy.enable_ip_geo : var.policy_defaults.enable_ip_geo
      enable_malware             = policy.enable_malware != null ? policy.enable_malware : var.policy_defaults.enable_malware
      enable_rate                = policy.enable_rate != null ? policy.enable_rate : var.policy_defaults.enable_rate
      enable_slow_post           = policy.enable_slow_post != null ? policy.enable_slow_post : var.policy_defaults.enable_slow_post
      enable_client_reputation   = policy.enable_client_reputation != null ? policy.enable_client_reputation : var.policy_defaults.enable_client_reputation
      enable_botman              = policy.enable_botman != null ? policy.enable_botman : var.policy_defaults.enable_botman

      # DoS Protection
      dos_origin_error_action       = policy.dos_origin_error_action != null ? policy.dos_origin_error_action : var.policy_defaults.dos_origin_error_action
      dos_post_page_requests_action = policy.dos_post_page_requests_action != null ? policy.dos_post_page_requests_action : var.policy_defaults.dos_post_page_requests_action
      dos_page_view_requests_action = policy.dos_page_view_requests_action != null ? policy.dos_page_view_requests_action : var.policy_defaults.dos_page_view_requests_action
      slow_post_action              = policy.slow_post_action != null ? policy.slow_post_action : var.policy_defaults.slow_post_action

      # WAF Actions
      waf_policy_action   = policy.waf_policy_action != null ? policy.waf_policy_action : var.policy_defaults.waf_policy_action
      waf_wat_action      = policy.waf_wat_action != null ? policy.waf_wat_action : var.policy_defaults.waf_wat_action
      waf_protocol_action = policy.waf_protocol_action != null ? policy.waf_protocol_action : var.policy_defaults.waf_protocol_action
      waf_sql_action      = policy.waf_sql_action != null ? policy.waf_sql_action : var.policy_defaults.waf_sql_action
      waf_xss_action      = policy.waf_xss_action != null ? policy.waf_xss_action : var.policy_defaults.waf_xss_action
      waf_cmd_action      = policy.waf_cmd_action != null ? policy.waf_cmd_action : var.policy_defaults.waf_cmd_action
      waf_lfi_action      = policy.waf_lfi_action != null ? policy.waf_lfi_action : var.policy_defaults.waf_lfi_action
      waf_rfi_action      = policy.waf_rfi_action != null ? policy.waf_rfi_action : var.policy_defaults.waf_rfi_action
      waf_platform_action = policy.waf_platform_action != null ? policy.waf_platform_action : var.policy_defaults.waf_platform_action
      penalty_box_action  = policy.penalty_box_action != null ? policy.penalty_box_action : var.policy_defaults.penalty_box_action

      # Client Reputation Actions
      rep_web_attackers_high         = policy.rep_web_attackers_high != null ? policy.rep_web_attackers_high : var.policy_defaults.rep_web_attackers_high
      rep_web_attackers_high_shared  = policy.rep_web_attackers_high_shared != null ? policy.rep_web_attackers_high_shared : var.policy_defaults.rep_web_attackers_high_shared
      rep_web_attackers_low          = policy.rep_web_attackers_low != null ? policy.rep_web_attackers_low : var.policy_defaults.rep_web_attackers_low
      rep_web_attackers_low_shared   = policy.rep_web_attackers_low_shared != null ? policy.rep_web_attackers_low_shared : var.policy_defaults.rep_web_attackers_low_shared
      rep_dos_attackers_high         = policy.rep_dos_attackers_high != null ? policy.rep_dos_attackers_high : var.policy_defaults.rep_dos_attackers_high
      rep_dos_attackers_high_shared  = policy.rep_dos_attackers_high_shared != null ? policy.rep_dos_attackers_high_shared : var.policy_defaults.rep_dos_attackers_high_shared
      rep_dos_attackers_low          = policy.rep_dos_attackers_low != null ? policy.rep_dos_attackers_low : var.policy_defaults.rep_dos_attackers_low
      rep_dos_attackers_low_shared   = policy.rep_dos_attackers_low_shared != null ? policy.rep_dos_attackers_low_shared : var.policy_defaults.rep_dos_attackers_low_shared
      rep_scanning_tools_high        = policy.rep_scanning_tools_high != null ? policy.rep_scanning_tools_high : var.policy_defaults.rep_scanning_tools_high
      rep_scanning_tools_high_shared = policy.rep_scanning_tools_high_shared != null ? policy.rep_scanning_tools_high_shared : var.policy_defaults.rep_scanning_tools_high_shared
      rep_scanning_tools_low         = policy.rep_scanning_tools_low != null ? policy.rep_scanning_tools_low : var.policy_defaults.rep_scanning_tools_low
      rep_scanning_tools_low_shared  = policy.rep_scanning_tools_low_shared != null ? policy.rep_scanning_tools_low_shared : var.policy_defaults.rep_scanning_tools_low_shared
      rep_web_scrapers_high          = policy.rep_web_scrapers_high != null ? policy.rep_web_scrapers_high : var.policy_defaults.rep_web_scrapers_high
      rep_web_scrapers_high_shared   = policy.rep_web_scrapers_high_shared != null ? policy.rep_web_scrapers_high_shared : var.policy_defaults.rep_web_scrapers_high_shared
      rep_web_scrapers_low           = policy.rep_web_scrapers_low != null ? policy.rep_web_scrapers_low : var.policy_defaults.rep_web_scrapers_low
      rep_web_scrapers_low_shared    = policy.rep_web_scrapers_low_shared != null ? policy.rep_web_scrapers_low_shared : var.policy_defaults.rep_web_scrapers_low_shared

      # Bot Manager General Settings
      botman_type               = policy.botman_type != null ? policy.botman_type : var.policy_defaults.botman_type
      add_akamai_bot_header     = policy.add_akamai_bot_header != null ? policy.add_akamai_bot_header : var.policy_defaults.add_akamai_bot_header
      enable_active_detections  = policy.enable_active_detections != null ? policy.enable_active_detections : var.policy_defaults.enable_active_detections
      enable_browser_validation = policy.enable_browser_validation != null ? policy.enable_browser_validation : var.policy_defaults.enable_browser_validation
      remove_botman_cookies     = policy.remove_botman_cookies != null ? policy.remove_botman_cookies : var.policy_defaults.remove_botman_cookies
      third_party_proxy         = policy.third_party_proxy != null ? policy.third_party_proxy : var.policy_defaults.third_party_proxy

      # Bot Category Actions
      bot_site_monitoring_and_web_development = policy.bot_site_monitoring_and_web_development != null ? policy.bot_site_monitoring_and_web_development : var.policy_defaults.bot_site_monitoring_and_web_development
      bot_academic_or_research                = policy.bot_academic_or_research != null ? policy.bot_academic_or_research : var.policy_defaults.bot_academic_or_research
      bot_job_search_engine                   = policy.bot_job_search_engine != null ? policy.bot_job_search_engine : var.policy_defaults.bot_job_search_engine
      bot_artificial_intelligence_ai          = policy.bot_artificial_intelligence_ai != null ? policy.bot_artificial_intelligence_ai : var.policy_defaults.bot_artificial_intelligence_ai
      bot_online_advertising                  = policy.bot_online_advertising != null ? policy.bot_online_advertising : var.policy_defaults.bot_online_advertising
      bot_ecommerce_search_engine             = policy.bot_ecommerce_search_engine != null ? policy.bot_ecommerce_search_engine : var.policy_defaults.bot_ecommerce_search_engine
      bot_web_search_engine                   = policy.bot_web_search_engine != null ? policy.bot_web_search_engine : var.policy_defaults.bot_web_search_engine
      bot_enterprise_data_aggregator          = policy.bot_enterprise_data_aggregator != null ? policy.bot_enterprise_data_aggregator : var.policy_defaults.bot_enterprise_data_aggregator
      bot_financial_services                  = policy.bot_financial_services != null ? policy.bot_financial_services : var.policy_defaults.bot_financial_services
      bot_social_media_or_blog                = policy.bot_social_media_or_blog != null ? policy.bot_social_media_or_blog : var.policy_defaults.bot_social_media_or_blog
      bot_web_archiver                        = policy.bot_web_archiver != null ? policy.bot_web_archiver : var.policy_defaults.bot_web_archiver
      bot_business_intelligence               = policy.bot_business_intelligence != null ? policy.bot_business_intelligence : var.policy_defaults.bot_business_intelligence
      bot_news_aggregator                     = policy.bot_news_aggregator != null ? policy.bot_news_aggregator : var.policy_defaults.bot_news_aggregator
      bot_rss_feed_reader                     = policy.bot_rss_feed_reader != null ? policy.bot_rss_feed_reader : var.policy_defaults.bot_rss_feed_reader
      bot_financial_account_aggregator        = policy.bot_financial_account_aggregator != null ? policy.bot_financial_account_aggregator : var.policy_defaults.bot_financial_account_aggregator
      bot_media_or_entertainment_search       = policy.bot_media_or_entertainment_search != null ? policy.bot_media_or_entertainment_search : var.policy_defaults.bot_media_or_entertainment_search
      bot_seo_analytics_or_marketing          = policy.bot_seo_analytics_or_marketing != null ? policy.bot_seo_analytics_or_marketing : var.policy_defaults.bot_seo_analytics_or_marketing

      # Bot Transparent Detection Actions
      bot_impersonators_of_known_bots            = policy.bot_impersonators_of_known_bots != null ? policy.bot_impersonators_of_known_bots : var.policy_defaults.bot_impersonators_of_known_bots
      bot_development_frameworks                 = policy.bot_development_frameworks != null ? policy.bot_development_frameworks : var.policy_defaults.bot_development_frameworks
      bot_http_libraries                         = policy.bot_http_libraries != null ? policy.bot_http_libraries : var.policy_defaults.bot_http_libraries
      bot_web_services_libraries                 = policy.bot_web_services_libraries != null ? policy.bot_web_services_libraries : var.policy_defaults.bot_web_services_libraries
      bot_open_source_crawlersscraping_platforms = policy.bot_open_source_crawlersscraping_platforms != null ? policy.bot_open_source_crawlersscraping_platforms : var.policy_defaults.bot_open_source_crawlersscraping_platforms
      bot_headless_browsersautomation_tools      = policy.bot_headless_browsersautomation_tools != null ? policy.bot_headless_browsersautomation_tools : var.policy_defaults.bot_headless_browsersautomation_tools
      bot_declared_bots_keyword_match            = policy.bot_declared_bots_keyword_match != null ? policy.bot_declared_bots_keyword_match : var.policy_defaults.bot_declared_bots_keyword_match
      bot_aggressive_web_crawlers                = policy.bot_aggressive_web_crawlers != null ? policy.bot_aggressive_web_crawlers : var.policy_defaults.bot_aggressive_web_crawlers
      bot_browser_impersonator                   = policy.bot_browser_impersonator != null ? policy.bot_browser_impersonator : var.policy_defaults.bot_browser_impersonator
      bot_web_scraper_reputation                 = policy.bot_web_scraper_reputation != null ? policy.bot_web_scraper_reputation : var.policy_defaults.bot_web_scraper_reputation

      # Bot Active Detection Actions
      bot_cookie_integrity_failed                       = policy.bot_cookie_integrity_failed != null ? policy.bot_cookie_integrity_failed : var.policy_defaults.bot_cookie_integrity_failed
      bot_session_validation                            = policy.bot_session_validation != null ? policy.bot_session_validation : var.policy_defaults.bot_session_validation
      bot_client_disabled_javascript_noscript_triggered = policy.bot_client_disabled_javascript_noscript_triggered != null ? policy.bot_client_disabled_javascript_noscript_triggered : var.policy_defaults.bot_client_disabled_javascript_noscript_triggered
      bot_javascript_fingerprint_anomaly                = policy.bot_javascript_fingerprint_anomaly != null ? policy.bot_javascript_fingerprint_anomaly : var.policy_defaults.bot_javascript_fingerprint_anomaly
      bot_javascript_fingerprint_not_received           = policy.bot_javascript_fingerprint_not_received != null ? policy.bot_javascript_fingerprint_not_received : var.policy_defaults.bot_javascript_fingerprint_not_received
    }
  }
}

# -------------------------------------------------
# Security Policies (iterable — called with for_each)
# -------------------------------------------------
module "security-policy" {
  for_each = local.resolved_policies
  source   = "git::https://github.com/akamai/terraform-templates-modules.git//aap-asm/security-policy?ref=v2.0.0"

  config_id     = module.security-config.config_id
  policy_name   = each.value.policy_name
  policy_prefix = each.value.policy_prefix
  hostnames     = each.value.hostnames

  match_target_sequence = index(keys(local.resolved_policies), each.key)
  bypass_network_lists  = module.security-config.bypass_network_lists

  # Protection Toggles
  enable_waf                 = each.value.enable_waf
  enable_request_constraints = each.value.enable_request_constraints
  enable_ip_geo              = each.value.enable_ip_geo
  enable_malware             = each.value.enable_malware
  enable_rate                = each.value.enable_rate
  enable_slow_post           = each.value.enable_slow_post
  enable_client_reputation   = each.value.enable_client_reputation
  enable_botman              = each.value.enable_botman

  # IP/Geo Firewall
  client_lists_ipblock           = local.client_lists_ipblock
  client_lists_geoblock          = local.client_lists_geoblock
  client_lists_asnblock          = local.client_lists_asnblock
  client_lists_exception_ipblock = local.client_lists_ipblock_exception

  # Rate Policy Actions
  rate_policy_origin_error_id       = module.security-config.rate_policy_origin_error_id
  rate_policy_post_page_requests_id = module.security-config.rate_policy_post_page_requests_id
  rate_policy_page_view_requests_id = module.security-config.rate_policy_page_view_requests_id

  # DoS Protection
  dos_origin_error_action       = each.value.dos_origin_error_action
  dos_post_page_requests_action = each.value.dos_post_page_requests_action
  dos_page_view_requests_action = each.value.dos_page_view_requests_action
  slow_post_action              = each.value.slow_post_action

  # WAF Actions
  waf_policy_action   = each.value.waf_policy_action
  waf_wat_action      = each.value.waf_wat_action
  waf_protocol_action = each.value.waf_protocol_action
  waf_sql_action      = each.value.waf_sql_action
  waf_xss_action      = each.value.waf_xss_action
  waf_cmd_action      = each.value.waf_cmd_action
  waf_lfi_action      = each.value.waf_lfi_action
  waf_rfi_action      = each.value.waf_rfi_action
  waf_platform_action = each.value.waf_platform_action
  penalty_box_action  = each.value.penalty_box_action

  # Client Reputation
  reputation_profile_ids         = module.security-config.reputation_profile_ids
  rep_web_attackers_high         = each.value.rep_web_attackers_high
  rep_web_attackers_high_shared  = each.value.rep_web_attackers_high_shared
  rep_web_attackers_low          = each.value.rep_web_attackers_low
  rep_web_attackers_low_shared   = each.value.rep_web_attackers_low_shared
  rep_dos_attackers_high         = each.value.rep_dos_attackers_high
  rep_dos_attackers_high_shared  = each.value.rep_dos_attackers_high_shared
  rep_dos_attackers_low          = each.value.rep_dos_attackers_low
  rep_dos_attackers_low_shared   = each.value.rep_dos_attackers_low_shared
  rep_scanning_tools_high        = each.value.rep_scanning_tools_high
  rep_scanning_tools_high_shared = each.value.rep_scanning_tools_high_shared
  rep_scanning_tools_low         = each.value.rep_scanning_tools_low
  rep_scanning_tools_low_shared  = each.value.rep_scanning_tools_low_shared
  rep_web_scrapers_high          = each.value.rep_web_scrapers_high
  rep_web_scrapers_high_shared   = each.value.rep_web_scrapers_high_shared
  rep_web_scrapers_low           = each.value.rep_web_scrapers_low
  rep_web_scrapers_low_shared    = each.value.rep_web_scrapers_low_shared

  # Bot Manager General Settings
  botman_type               = each.value.botman_type
  add_akamai_bot_header     = each.value.add_akamai_bot_header
  enable_active_detections  = each.value.enable_active_detections
  enable_browser_validation = each.value.enable_browser_validation
  remove_botman_cookies     = each.value.remove_botman_cookies
  third_party_proxy         = each.value.third_party_proxy

  # Bot Category Actions
  bot_site_monitoring_and_web_development = each.value.bot_site_monitoring_and_web_development
  bot_academic_or_research                = each.value.bot_academic_or_research
  bot_job_search_engine                   = each.value.bot_job_search_engine
  bot_artificial_intelligence_ai          = each.value.bot_artificial_intelligence_ai
  bot_online_advertising                  = each.value.bot_online_advertising
  bot_ecommerce_search_engine             = each.value.bot_ecommerce_search_engine
  bot_web_search_engine                   = each.value.bot_web_search_engine
  bot_enterprise_data_aggregator          = each.value.bot_enterprise_data_aggregator
  bot_financial_services                  = each.value.bot_financial_services
  bot_social_media_or_blog                = each.value.bot_social_media_or_blog
  bot_web_archiver                        = each.value.bot_web_archiver
  bot_business_intelligence               = each.value.bot_business_intelligence
  bot_news_aggregator                     = each.value.bot_news_aggregator
  bot_rss_feed_reader                     = each.value.bot_rss_feed_reader
  bot_financial_account_aggregator        = each.value.bot_financial_account_aggregator
  bot_media_or_entertainment_search       = each.value.bot_media_or_entertainment_search
  bot_seo_analytics_or_marketing          = each.value.bot_seo_analytics_or_marketing

  # Bot Transparent Detection Actions
  bot_impersonators_of_known_bots            = each.value.bot_impersonators_of_known_bots
  bot_development_frameworks                 = each.value.bot_development_frameworks
  bot_http_libraries                         = each.value.bot_http_libraries
  bot_web_services_libraries                 = each.value.bot_web_services_libraries
  bot_open_source_crawlersscraping_platforms = each.value.bot_open_source_crawlersscraping_platforms
  bot_headless_browsersautomation_tools      = each.value.bot_headless_browsersautomation_tools
  bot_declared_bots_keyword_match            = each.value.bot_declared_bots_keyword_match
  bot_aggressive_web_crawlers                = each.value.bot_aggressive_web_crawlers
  bot_browser_impersonator                   = each.value.bot_browser_impersonator
  bot_web_scraper_reputation                 = each.value.bot_web_scraper_reputation

  # Bot Active Detection Actions
  bot_cookie_integrity_failed                       = each.value.bot_cookie_integrity_failed
  bot_session_validation                            = each.value.bot_session_validation
  bot_client_disabled_javascript_noscript_triggered = each.value.bot_client_disabled_javascript_noscript_triggered
  bot_javascript_fingerprint_anomaly                = each.value.bot_javascript_fingerprint_anomaly
  bot_javascript_fingerprint_not_received           = each.value.bot_javascript_fingerprint_not_received

  depends_on = [module.security-config]
}

# -------------------------------------------------
# Activation (called once, after all policies)
# -------------------------------------------------
module "activate-security" {
  source                          = "git::https://github.com/akamai/terraform-templates-modules.git//aap-asm/activate-security?ref=v2.0.0"
  config_name                     = module.security-config.config_name
  config_id                       = module.security-config.config_id
  activate_to_staging             = var.activate_to_staging
  activation_to_staging_exists    = var.activation_to_staging_exists
  activate_to_production          = var.activate_to_production
  activation_to_production_exists = var.activation_to_production_exists
  notification_emails             = var.emails
  activation_notes                = var.version_notes
  depends_on = [
    module.security-config,
    module.security-policy
  ]
}
