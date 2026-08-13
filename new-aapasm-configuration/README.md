<!-- BEGIN_TF_DOCS -->

# Onboarding: App & API Protector (AAP) and the Advanced Security Management (ASM)

This template creates a complete Akamai security configuration, consisting of:

* **Client Lists** (optional) — IP block, geo block, ASN block and security bypass lists. You can also reuse existing lists by providing their IDs.
* **Security Configuration** — the container for all policies, plus the config-level resources (advanced settings, rate policies, client reputation profiles).
* **Security Policies** — one or **many** policies, each protecting its own hostnames with independently configurable protection actions (WAF, DoS, Client Reputation, Bot Manager).
* **Activation** — pushes the configuration to the Akamai staging and/or production networks.

It supports multiple environments (e.g. dev, qa, prod) if required by the customer, and the initial configuration for BVM (Bot Visibility and Management) or BMS (Bot Management Standard).

## Prerequisites

Before you start, make sure you have:

* [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.9.0
* [PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell) 7+ to run the deployment script
* Akamai API credentials (typically in `~/.edgerc`) with read-write access to the Application Security, Client Lists and Bot Manager APIs
* The Akamai **group name** where the configuration will be created (visible in Akamai Control Center)
* The **hostnames** you want to protect — they must already exist in a delivery property on the same contract

## Authentication

Please refer to [Terraform Overview](https://techdocs.akamai.com/terraform/docs/overview) and [Terraform Alternative authentication](https://techdocs.akamai.com/terraform/docs/gs-authentication) for more details on how to authenticate to Akamai when using Terraform.

## Usage

### Step 1 — Clone the repository

```bash
> git clone <git url>
> cd terraform-templates/new-aapasm-configuration/
```

### Step 2 — Set up your environment(s)

The `./environments` folder holds one subdirectory per environment (e.g. `dev`, `qa`, `prod`), each with its own `tfvars` file and Terraform state, so environments never overwrite each other.

1. Keep (or create) one subdirectory per environment you need. If you only need a single environment, keep just one directory (you can name it "prod") and delete the others.
2. The `tfvars` filename must be prefixed with the environment name: for "prod" the file is `prod.tfvars`.
3. Rename the example file by removing the `.dist` extension (e.g. `prod.tfvars.dist` → `prod.tfvars`) and fill in the required values. Each parameter is documented with inline instructions inside the file.

### Step 3 — Define your security policies

This template supports **multiple security policies** in a single security configuration. In your `tfvars` file:

1. Set the baseline protection actions once in `policy_defaults`. These apply to every policy unless overridden.
2. Define each policy in the `policies` map. A policy only needs `policy_name`, `policy_prefix` and `hostnames` — everything else is inherited from `policy_defaults`, and any field can be overridden per policy.

```hcl
policies = {
  main = {
    policy_name   = "main-website"
    policy_prefix = "MN01"                      # exactly 4 uppercase alphanumeric characters, unique per policy
    hostnames     = ["www.example.com"]
  }
  api = {
    policy_name    = "api-policy"
    policy_prefix  = "AP01"
    hostnames      = ["api.example.com"]
    waf_sql_action = "deny"                     # override: stricter WAF action for this policy only
    enable_botman  = false                      # override: no Bot Manager for this policy
  }
}
```

Keep in mind:

* Map keys (`main`, `api`, ...) are stable identifiers — renaming a key destroys and recreates that policy.
* Hostnames must be lowercase and should not overlap between policies.
* The security configuration automatically covers the union of all policy hostnames.

### Step 4 — Deploy

Run the deployment script `../deploy.ps1`. This script is written in PowerShell and acts as an orchestrator for Terraform. It performs the individual save and activation actions and handles the multi-environment directories and state files.

    A common flow is as follows (with "prod" as the environment):
    1. Save the changes only (creates/updates the configuration without activating it):
    ```bash
    PS> .\deploy.ps1 aapasm -Env prod -Save -Notes "Some user notes"
    ```

    2. Activate to staging (test against the Akamai staging network before going live):
    ```bash
    PS> .\deploy.ps1 aapasm -Env prod -ActivateStaging
    ```

    3. Activate to production:
    ```bash
    PS> .\deploy.ps1 aapasm -Env prod -ActivateProduction
    ```

    Options:
    * Add the `-Dry` option to any command to preview the changes without applying anything. Recommended for a first run.
    * Add the `-Debug` option to log all the Terraform actions in a file stored in the specific environment directory.
    * You can delete all the resources when you don't need them. Keep in mind some resources can't be deleted, in which case the `terraform destroy` operation will fail as a consequence.
    ```bash
    PS> .\deploy.ps1 aapasm -Env dev -Destroy
    ```

### Step 5 — Verify

After a successful run, Terraform outputs the security configuration ID (`config_id`) and a map of policy keys to policy IDs (`security_policy_ids`). You can review the resulting configuration in Akamai Control Center under Security Configurations.

## Known Errors
### Client Reputation
You may see the following error during the first terraform execution because Client Reputation may not be available/ready in time. A 20s delay has been added to allow for Client Reputation to become available. However in some occurrences it may take longer. Instead of waiting for longer we retry automatically the apply if the error happens.

```hcl
│ Error: Provider produced inconsistent final plan
│
│ When expanding the plan for module.security-policy["main"].akamai_appsec_reputation_profile_action.web_attackers_high_threat[0]
│ This is a bug in the provider, which should be reported in the provider's own issue tracker.
```

### Destroy INTERNAL-SERVER-ERROR
This is probably the reason for another race condition with no further details. A retry happens automatically to overcome this error. The Destroy will succeed afterwards.

```hcl
│ Error: Title: Internal Server Error; Type: https://problems.luna.akamaiapis.net/appsec-configuration/error-types/INTERNAL-SERVER-ERROR; Detail: Error occurred while processing the request.
```

# Usage
Basic usage of this module is as follows:

```hcl
module "example" {
  	 source  = "<module-location>"
  
	 # Required variables
  	 config_name  = <string>
  	 description  = <string>
  	 environment  = <string>
  	 group_name  = <string>
  	 inspection_size  = <number>
  	 policies  = <map(object({
	    # Required
	    policy_name   = string
	    policy_prefix = string
	    hostnames     = list(string)
	
	    # Protection Toggles (optional overrides)
	    enable_waf                 = optional(bool)
	    enable_request_constraints = optional(bool)
	    enable_ip_geo              = optional(bool)
	    enable_malware             = optional(bool)
	    enable_rate                = optional(bool)
	    enable_slow_post           = optional(bool)
	    enable_client_reputation   = optional(bool)
	    enable_botman              = optional(bool)
	
	    # DoS Protection
	    dos_origin_error_action       = optional(string)
	    dos_post_page_requests_action = optional(string)
	    dos_page_view_requests_action = optional(string)
	    slow_post_action              = optional(string)
	
	    # WAF Actions
	    waf_policy_action   = optional(string)
	    waf_wat_action      = optional(string)
	    waf_protocol_action = optional(string)
	    waf_sql_action      = optional(string)
	    waf_xss_action      = optional(string)
	    waf_cmd_action      = optional(string)
	    waf_lfi_action      = optional(string)
	    waf_rfi_action      = optional(string)
	    waf_platform_action = optional(string)
	    penalty_box_action  = optional(string)
	
	    # Client Reputation Actions
	    rep_web_attackers_high         = optional(string)
	    rep_web_attackers_high_shared  = optional(string)
	    rep_web_attackers_low          = optional(string)
	    rep_web_attackers_low_shared   = optional(string)
	    rep_dos_attackers_high         = optional(string)
	    rep_dos_attackers_high_shared  = optional(string)
	    rep_dos_attackers_low          = optional(string)
	    rep_dos_attackers_low_shared   = optional(string)
	    rep_scanning_tools_high        = optional(string)
	    rep_scanning_tools_high_shared = optional(string)
	    rep_scanning_tools_low         = optional(string)
	    rep_scanning_tools_low_shared  = optional(string)
	    rep_web_scrapers_high          = optional(string)
	    rep_web_scrapers_high_shared   = optional(string)
	    rep_web_scrapers_low           = optional(string)
	    rep_web_scrapers_low_shared    = optional(string)
	
	    # Bot Manager General Settings
	    botman_type               = optional(string)
	    add_akamai_bot_header     = optional(bool)
	    enable_active_detections  = optional(bool)
	    enable_browser_validation = optional(bool)
	    remove_botman_cookies     = optional(bool)
	    third_party_proxy         = optional(bool)
	
	    # Bot Category Actions
	    bot_site_monitoring_and_web_development = optional(string)
	    bot_academic_or_research                = optional(string)
	    bot_job_search_engine                   = optional(string)
	    bot_artificial_intelligence_ai          = optional(string)
	    bot_online_advertising                  = optional(string)
	    bot_ecommerce_search_engine             = optional(string)
	    bot_web_search_engine                   = optional(string)
	    bot_enterprise_data_aggregator          = optional(string)
	    bot_financial_services                  = optional(string)
	    bot_social_media_or_blog                = optional(string)
	    bot_web_archiver                        = optional(string)
	    bot_business_intelligence               = optional(string)
	    bot_news_aggregator                     = optional(string)
	    bot_rss_feed_reader                     = optional(string)
	    bot_financial_account_aggregator        = optional(string)
	    bot_media_or_entertainment_search       = optional(string)
	    bot_seo_analytics_or_marketing          = optional(string)
	
	    # Bot Transparent Detection Actions
	    bot_impersonators_of_known_bots            = optional(string)
	    bot_development_frameworks                 = optional(string)
	    bot_http_libraries                         = optional(string)
	    bot_web_services_libraries                 = optional(string)
	    bot_open_source_crawlersscraping_platforms = optional(string)
	    bot_headless_browsersautomation_tools      = optional(string)
	    bot_declared_bots_keyword_match            = optional(string)
	    bot_aggressive_web_crawlers                = optional(string)
	    bot_browser_impersonator                   = optional(string)
	    bot_web_scraper_reputation                 = optional(string)
	
	    # Bot Active Detection Actions
	    bot_cookie_integrity_failed                       = optional(string)
	    bot_session_validation                            = optional(string)
	    bot_client_disabled_javascript_noscript_triggered = optional(string)
	    bot_javascript_fingerprint_anomaly                = optional(string)
	    bot_javascript_fingerprint_not_received           = optional(string)
	  }))>
  	 policy_defaults  = <object({
	    # Protection Toggles
	    enable_waf                 = bool
	    enable_request_constraints = bool
	    enable_ip_geo              = bool
	    enable_malware             = bool
	    enable_rate                = bool
	    enable_slow_post           = bool
	    enable_client_reputation   = bool
	    enable_botman              = bool
	
	    # DoS Protection
	    dos_origin_error_action       = string
	    dos_post_page_requests_action = string
	    dos_page_view_requests_action = string
	    slow_post_action              = string
	
	    # WAF Actions
	    waf_policy_action   = string
	    waf_wat_action      = string
	    waf_protocol_action = string
	    waf_sql_action      = string
	    waf_xss_action      = string
	    waf_cmd_action      = string
	    waf_lfi_action      = string
	    waf_rfi_action      = string
	    waf_platform_action = string
	    penalty_box_action  = string
	
	    # Client Reputation Actions
	    rep_web_attackers_high         = optional(string, "alert")
	    rep_web_attackers_high_shared  = optional(string, "alert")
	    rep_web_attackers_low          = optional(string, "none")
	    rep_web_attackers_low_shared   = optional(string, "none")
	    rep_dos_attackers_high         = optional(string, "alert")
	    rep_dos_attackers_high_shared  = optional(string, "alert")
	    rep_dos_attackers_low          = optional(string, "none")
	    rep_dos_attackers_low_shared   = optional(string, "none")
	    rep_scanning_tools_high        = optional(string, "alert")
	    rep_scanning_tools_high_shared = optional(string, "alert")
	    rep_scanning_tools_low         = optional(string, "none")
	    rep_scanning_tools_low_shared  = optional(string, "none")
	    rep_web_scrapers_high          = optional(string, "alert")
	    rep_web_scrapers_high_shared   = optional(string, "alert")
	    rep_web_scrapers_low           = optional(string, "none")
	    rep_web_scrapers_low_shared    = optional(string, "none")
	
	    # Bot Manager General Settings
	    botman_type               = optional(string, "bvm")
	    add_akamai_bot_header     = optional(bool, false)
	    enable_active_detections  = optional(bool, false)
	    enable_browser_validation = optional(bool, false)
	    remove_botman_cookies     = optional(bool, true)
	    third_party_proxy         = optional(bool, false)
	
	    # Bot Category Actions
	    bot_site_monitoring_and_web_development = optional(string, "alert")
	    bot_academic_or_research                = optional(string, "alert")
	    bot_job_search_engine                   = optional(string, "alert")
	    bot_artificial_intelligence_ai          = optional(string, "alert")
	    bot_online_advertising                  = optional(string, "alert")
	    bot_ecommerce_search_engine             = optional(string, "alert")
	    bot_web_search_engine                   = optional(string, "alert")
	    bot_enterprise_data_aggregator          = optional(string, "alert")
	    bot_financial_services                  = optional(string, "alert")
	    bot_social_media_or_blog                = optional(string, "alert")
	    bot_web_archiver                        = optional(string, "alert")
	    bot_business_intelligence               = optional(string, "alert")
	    bot_news_aggregator                     = optional(string, "alert")
	    bot_rss_feed_reader                     = optional(string, "alert")
	    bot_financial_account_aggregator        = optional(string, "alert")
	    bot_media_or_entertainment_search       = optional(string, "alert")
	    bot_seo_analytics_or_marketing          = optional(string, "alert")
	
	    # Bot Transparent Detection Actions
	    bot_impersonators_of_known_bots            = optional(string, "alert")
	    bot_development_frameworks                 = optional(string, "alert")
	    bot_http_libraries                         = optional(string, "alert")
	    bot_web_services_libraries                 = optional(string, "alert")
	    bot_open_source_crawlersscraping_platforms = optional(string, "alert")
	    bot_headless_browsersautomation_tools      = optional(string, "alert")
	    bot_declared_bots_keyword_match            = optional(string, "alert")
	    bot_aggressive_web_crawlers                = optional(string, "alert")
	    bot_browser_impersonator                   = optional(string, "alert")
	    bot_web_scraper_reputation                 = optional(string, "alert")
	
	    # Bot Active Detection Actions
	    bot_cookie_integrity_failed                       = optional(string, "alert")
	    bot_session_validation                            = optional(string, "alert")
	    bot_client_disabled_javascript_noscript_triggered = optional(string, "alert")
	    bot_javascript_fingerprint_anomaly                = optional(string, "alert")
	    bot_javascript_fingerprint_not_received           = optional(string, "alert")
	  })>
  
	 # Optional variables
  	 activate_to_production  = <bool> | default: false
  	 activate_to_staging  = <bool> | default: false
  	 activation_notes  = <string> | default: "Activated by Terraform"
  	 activation_to_production_exists  = <bool> | default: false
  	 activation_to_staging_exists  = <bool> | default: false
  	 akamai_access_token  = <string> | default: ""
  	 akamai_account_key  = <string> | default: ""
  	 akamai_client_secret  = <string> | default: ""
  	 akamai_client_token  = <string> | default: ""
  	 akamai_host  = <string> | default: ""
  	 client_lists_asnblock  = <list(string)> | default: []
  	 client_lists_geoblock  = <list(string)> | default: []
  	 client_lists_ipblock  = <list(string)> | default: []
  	 client_lists_ipblock_exception  = <list(string)> | default: []
  	 client_lists_pragmabypass  = <list(string)> | default: []
  	 client_lists_rcbypass  = <list(string)> | default: []
  	 client_lists_securitybypass  = <list(string)> | default: []
  	 create_client_lists  = <bool> | default: true
  	 edgerc_path  = <string> | default: "~/.edgerc"
  	 edgerc_section  = <string> | default: "default"
  	 emails  = <list(string)> | default: [
  "noreply@akamai.com"
]
  	 version_notes  = <string> | default: "Initial Config"
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_akamai"></a> [akamai](#requirement\_akamai) | ~> 10.1 |

## Resources

| Name | Type |
|------|------|
| [akamai_contract.contract](https://registry.terraform.io/providers/akamai/akamai/latest/docs/data-sources/contract) | data source |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_activate-security"></a> [activate-security](#module\_activate-security) | git::https://github.com/akamai/terraform-templates-modules.git//aap-asm/activate-security | v2.0.0 |
| <a name="module_client-lists"></a> [client-lists](#module\_client-lists) | git::https://github.com/akamai/terraform-templates-modules.git//aap-asm/client-lists | v2.0.0 |
| <a name="module_security-config"></a> [security-config](#module\_security-config) | git::https://github.com/akamai/terraform-templates-modules.git//aap-asm/security-config | v2.0.0 |
| <a name="module_security-policy"></a> [security-policy](#module\_security-policy) | git::https://github.com/akamai/terraform-templates-modules.git//aap-asm/security-policy | v2.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_config_name"></a> [config\_name](#input\_config\_name) | Security configuration name | `string` | n/a | yes |
| <a name="input_description"></a> [description](#input\_description) | Security configuration description | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment (e.g. dev, qa, prod) | `string` | n/a | yes |
| <a name="input_group_name"></a> [group\_name](#input\_group\_name) | Akamai Group Name | `string` | n/a | yes |
| <a name="input_inspection_size"></a> [inspection\_size](#input\_inspection\_size) | Request body inspection limit | `number` | n/a | yes |
| <a name="input_policies"></a> [policies](#input\_policies) | Map of security policies to create. Each key is a stable identifier (renaming destroys/recreates). Required per entry: policy\_name, policy\_prefix, hostnames. All other fields are optional and override policy\_defaults when set. | <pre>map(object({<br/>    # Required<br/>    policy_name   = string<br/>    policy_prefix = string<br/>    hostnames     = list(string)<br/><br/>    # Protection Toggles (optional overrides)<br/>    enable_waf                 = optional(bool)<br/>    enable_request_constraints = optional(bool)<br/>    enable_ip_geo              = optional(bool)<br/>    enable_malware             = optional(bool)<br/>    enable_rate                = optional(bool)<br/>    enable_slow_post           = optional(bool)<br/>    enable_client_reputation   = optional(bool)<br/>    enable_botman              = optional(bool)<br/><br/>    # DoS Protection<br/>    dos_origin_error_action       = optional(string)<br/>    dos_post_page_requests_action = optional(string)<br/>    dos_page_view_requests_action = optional(string)<br/>    slow_post_action              = optional(string)<br/><br/>    # WAF Actions<br/>    waf_policy_action   = optional(string)<br/>    waf_wat_action      = optional(string)<br/>    waf_protocol_action = optional(string)<br/>    waf_sql_action      = optional(string)<br/>    waf_xss_action      = optional(string)<br/>    waf_cmd_action      = optional(string)<br/>    waf_lfi_action      = optional(string)<br/>    waf_rfi_action      = optional(string)<br/>    waf_platform_action = optional(string)<br/>    penalty_box_action  = optional(string)<br/><br/>    # Client Reputation Actions<br/>    rep_web_attackers_high         = optional(string)<br/>    rep_web_attackers_high_shared  = optional(string)<br/>    rep_web_attackers_low          = optional(string)<br/>    rep_web_attackers_low_shared   = optional(string)<br/>    rep_dos_attackers_high         = optional(string)<br/>    rep_dos_attackers_high_shared  = optional(string)<br/>    rep_dos_attackers_low          = optional(string)<br/>    rep_dos_attackers_low_shared   = optional(string)<br/>    rep_scanning_tools_high        = optional(string)<br/>    rep_scanning_tools_high_shared = optional(string)<br/>    rep_scanning_tools_low         = optional(string)<br/>    rep_scanning_tools_low_shared  = optional(string)<br/>    rep_web_scrapers_high          = optional(string)<br/>    rep_web_scrapers_high_shared   = optional(string)<br/>    rep_web_scrapers_low           = optional(string)<br/>    rep_web_scrapers_low_shared    = optional(string)<br/><br/>    # Bot Manager General Settings<br/>    botman_type               = optional(string)<br/>    add_akamai_bot_header     = optional(bool)<br/>    enable_active_detections  = optional(bool)<br/>    enable_browser_validation = optional(bool)<br/>    remove_botman_cookies     = optional(bool)<br/>    third_party_proxy         = optional(bool)<br/><br/>    # Bot Category Actions<br/>    bot_site_monitoring_and_web_development = optional(string)<br/>    bot_academic_or_research                = optional(string)<br/>    bot_job_search_engine                   = optional(string)<br/>    bot_artificial_intelligence_ai          = optional(string)<br/>    bot_online_advertising                  = optional(string)<br/>    bot_ecommerce_search_engine             = optional(string)<br/>    bot_web_search_engine                   = optional(string)<br/>    bot_enterprise_data_aggregator          = optional(string)<br/>    bot_financial_services                  = optional(string)<br/>    bot_social_media_or_blog                = optional(string)<br/>    bot_web_archiver                        = optional(string)<br/>    bot_business_intelligence               = optional(string)<br/>    bot_news_aggregator                     = optional(string)<br/>    bot_rss_feed_reader                     = optional(string)<br/>    bot_financial_account_aggregator        = optional(string)<br/>    bot_media_or_entertainment_search       = optional(string)<br/>    bot_seo_analytics_or_marketing          = optional(string)<br/><br/>    # Bot Transparent Detection Actions<br/>    bot_impersonators_of_known_bots            = optional(string)<br/>    bot_development_frameworks                 = optional(string)<br/>    bot_http_libraries                         = optional(string)<br/>    bot_web_services_libraries                 = optional(string)<br/>    bot_open_source_crawlersscraping_platforms = optional(string)<br/>    bot_headless_browsersautomation_tools      = optional(string)<br/>    bot_declared_bots_keyword_match            = optional(string)<br/>    bot_aggressive_web_crawlers                = optional(string)<br/>    bot_browser_impersonator                   = optional(string)<br/>    bot_web_scraper_reputation                 = optional(string)<br/><br/>    # Bot Active Detection Actions<br/>    bot_cookie_integrity_failed                       = optional(string)<br/>    bot_session_validation                            = optional(string)<br/>    bot_client_disabled_javascript_noscript_triggered = optional(string)<br/>    bot_javascript_fingerprint_anomaly                = optional(string)<br/>    bot_javascript_fingerprint_not_received           = optional(string)<br/>  }))</pre> | n/a | yes |
| <a name="input_policy_defaults"></a> [policy\_defaults](#input\_policy\_defaults) | Default values for all security policies. Each policy inherits these unless it provides its own override. | <pre>object({<br/>    # Protection Toggles<br/>    enable_waf                 = bool<br/>    enable_request_constraints = bool<br/>    enable_ip_geo              = bool<br/>    enable_malware             = bool<br/>    enable_rate                = bool<br/>    enable_slow_post           = bool<br/>    enable_client_reputation   = bool<br/>    enable_botman              = bool<br/><br/>    # DoS Protection<br/>    dos_origin_error_action       = string<br/>    dos_post_page_requests_action = string<br/>    dos_page_view_requests_action = string<br/>    slow_post_action              = string<br/><br/>    # WAF Actions<br/>    waf_policy_action   = string<br/>    waf_wat_action      = string<br/>    waf_protocol_action = string<br/>    waf_sql_action      = string<br/>    waf_xss_action      = string<br/>    waf_cmd_action      = string<br/>    waf_lfi_action      = string<br/>    waf_rfi_action      = string<br/>    waf_platform_action = string<br/>    penalty_box_action  = string<br/><br/>    # Client Reputation Actions<br/>    rep_web_attackers_high         = optional(string, "alert")<br/>    rep_web_attackers_high_shared  = optional(string, "alert")<br/>    rep_web_attackers_low          = optional(string, "none")<br/>    rep_web_attackers_low_shared   = optional(string, "none")<br/>    rep_dos_attackers_high         = optional(string, "alert")<br/>    rep_dos_attackers_high_shared  = optional(string, "alert")<br/>    rep_dos_attackers_low          = optional(string, "none")<br/>    rep_dos_attackers_low_shared   = optional(string, "none")<br/>    rep_scanning_tools_high        = optional(string, "alert")<br/>    rep_scanning_tools_high_shared = optional(string, "alert")<br/>    rep_scanning_tools_low         = optional(string, "none")<br/>    rep_scanning_tools_low_shared  = optional(string, "none")<br/>    rep_web_scrapers_high          = optional(string, "alert")<br/>    rep_web_scrapers_high_shared   = optional(string, "alert")<br/>    rep_web_scrapers_low           = optional(string, "none")<br/>    rep_web_scrapers_low_shared    = optional(string, "none")<br/><br/>    # Bot Manager General Settings<br/>    botman_type               = optional(string, "bvm")<br/>    add_akamai_bot_header     = optional(bool, false)<br/>    enable_active_detections  = optional(bool, false)<br/>    enable_browser_validation = optional(bool, false)<br/>    remove_botman_cookies     = optional(bool, true)<br/>    third_party_proxy         = optional(bool, false)<br/><br/>    # Bot Category Actions<br/>    bot_site_monitoring_and_web_development = optional(string, "alert")<br/>    bot_academic_or_research                = optional(string, "alert")<br/>    bot_job_search_engine                   = optional(string, "alert")<br/>    bot_artificial_intelligence_ai          = optional(string, "alert")<br/>    bot_online_advertising                  = optional(string, "alert")<br/>    bot_ecommerce_search_engine             = optional(string, "alert")<br/>    bot_web_search_engine                   = optional(string, "alert")<br/>    bot_enterprise_data_aggregator          = optional(string, "alert")<br/>    bot_financial_services                  = optional(string, "alert")<br/>    bot_social_media_or_blog                = optional(string, "alert")<br/>    bot_web_archiver                        = optional(string, "alert")<br/>    bot_business_intelligence               = optional(string, "alert")<br/>    bot_news_aggregator                     = optional(string, "alert")<br/>    bot_rss_feed_reader                     = optional(string, "alert")<br/>    bot_financial_account_aggregator        = optional(string, "alert")<br/>    bot_media_or_entertainment_search       = optional(string, "alert")<br/>    bot_seo_analytics_or_marketing          = optional(string, "alert")<br/><br/>    # Bot Transparent Detection Actions<br/>    bot_impersonators_of_known_bots            = optional(string, "alert")<br/>    bot_development_frameworks                 = optional(string, "alert")<br/>    bot_http_libraries                         = optional(string, "alert")<br/>    bot_web_services_libraries                 = optional(string, "alert")<br/>    bot_open_source_crawlersscraping_platforms = optional(string, "alert")<br/>    bot_headless_browsersautomation_tools      = optional(string, "alert")<br/>    bot_declared_bots_keyword_match            = optional(string, "alert")<br/>    bot_aggressive_web_crawlers                = optional(string, "alert")<br/>    bot_browser_impersonator                   = optional(string, "alert")<br/>    bot_web_scraper_reputation                 = optional(string, "alert")<br/><br/>    # Bot Active Detection Actions<br/>    bot_cookie_integrity_failed                       = optional(string, "alert")<br/>    bot_session_validation                            = optional(string, "alert")<br/>    bot_client_disabled_javascript_noscript_triggered = optional(string, "alert")<br/>    bot_javascript_fingerprint_anomaly                = optional(string, "alert")<br/>    bot_javascript_fingerprint_not_received           = optional(string, "alert")<br/>  })</pre> | n/a | yes |
| <a name="input_activate_to_production"></a> [activate\_to\_production](#input\_activate\_to\_production) | Set to true to directly activate on the production network. | `bool` | `false` | no |
| <a name="input_activate_to_staging"></a> [activate\_to\_staging](#input\_activate\_to\_staging) | Set to true to directly activate on the staging network. | `bool` | `false` | no |
| <a name="input_activation_notes"></a> [activation\_notes](#input\_activation\_notes) | Notes for the activation | `string` | `"Activated by Terraform"` | no |
| <a name="input_activation_to_production_exists"></a> [activation\_to\_production\_exists](#input\_activation\_to\_production\_exists) | Do not modify. Flag used together with the logic in the activation resources for the initial activation to production. | `bool` | `false` | no |
| <a name="input_activation_to_staging_exists"></a> [activation\_to\_staging\_exists](#input\_activation\_to\_staging\_exists) | Do not modify. Flag used together with the logic in the activation resources for the initial activation to staging. | `bool` | `false` | no |
| <a name="input_akamai_access_token"></a> [akamai\_access\_token](#input\_akamai\_access\_token) | Akamai access\_token API credential | `string` | `""` | no |
| <a name="input_akamai_account_key"></a> [akamai\_account\_key](#input\_akamai\_account\_key) | Akamai Account Key | `string` | `""` | no |
| <a name="input_akamai_client_secret"></a> [akamai\_client\_secret](#input\_akamai\_client\_secret) | Akamai client\_secret API credential | `string` | `""` | no |
| <a name="input_akamai_client_token"></a> [akamai\_client\_token](#input\_akamai\_client\_token) | Akamai client\_token API credential | `string` | `""` | no |
| <a name="input_akamai_host"></a> [akamai\_host](#input\_akamai\_host) | Akamai host API credential | `string` | `""` | no |
| <a name="input_client_lists_asnblock"></a> [client\_lists\_asnblock](#input\_client\_lists\_asnblock) | ID(s) for the ASN Block Client List | `list(string)` | `[]` | no |
| <a name="input_client_lists_geoblock"></a> [client\_lists\_geoblock](#input\_client\_lists\_geoblock) | ID(s) for the Geo Block Client List | `list(string)` | `[]` | no |
| <a name="input_client_lists_ipblock"></a> [client\_lists\_ipblock](#input\_client\_lists\_ipblock) | ID(s) for the IP Block Client List | `list(string)` | `[]` | no |
| <a name="input_client_lists_ipblock_exception"></a> [client\_lists\_ipblock\_exception](#input\_client\_lists\_ipblock\_exception) | ID(s) for the IP Block Exceptions Client List | `list(string)` | `[]` | no |
| <a name="input_client_lists_pragmabypass"></a> [client\_lists\_pragmabypass](#input\_client\_lists\_pragmabypass) | ID(s) for the Pragma Bypass Client List | `list(string)` | `[]` | no |
| <a name="input_client_lists_rcbypass"></a> [client\_lists\_rcbypass](#input\_client\_lists\_rcbypass) | ID(s) for the Rate Control Bypass Client List | `list(string)` | `[]` | no |
| <a name="input_client_lists_securitybypass"></a> [client\_lists\_securitybypass](#input\_client\_lists\_securitybypass) | ID(s) for the Security Bypass Client List | `list(string)` | `[]` | no |
| <a name="input_create_client_lists"></a> [create\_client\_lists](#input\_create\_client\_lists) | Set to true to create new client lists, false to use existing IDs | `bool` | `true` | no |
| <a name="input_edgerc_path"></a> [edgerc\_path](#input\_edgerc\_path) | Specify path to the Akamai EdgeGrid authentication file that contains your Akamai API tokens. Typically ~/.edgerc. | `string` | `"~/.edgerc"` | no |
| <a name="input_edgerc_section"></a> [edgerc\_section](#input\_edgerc\_section) | Specify the section inside the edgerc file which can contain multiple sets of Akamai API tokens. Typically default. | `string` | `"default"` | no |
| <a name="input_emails"></a> [emails](#input\_emails) | List of emails for notifications | `list(string)` | <pre>[<br/>  "noreply@akamai.com"<br/>]</pre> | no |
| <a name="input_version_notes"></a> [version\_notes](#input\_version\_notes) | Property version notes. | `string` | `"Initial Config"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_config_id"></a> [config\_id](#output\_config\_id) | Security Configuration ID |
| <a name="output_security_policy_ids"></a> [security\_policy\_ids](#output\_security\_policy\_ids) | Map of policy keys to their Security Policy IDs |
<!-- END_TF_DOCS -->