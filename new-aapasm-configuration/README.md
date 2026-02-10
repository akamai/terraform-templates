<!-- BEGIN_TF_DOCS -->

# Onboarding: App & API Protector (AAP) and the Advanced Security Management (ASM)

Supports the creation of multiple environments (e.g. dev, qa, prod) if required by the customer.
Also supports creating the initial configuration for BVM (Bot Visibility and Management) or BMS (Bot Management Standard)

## Authentication

Please refer to [DevOps Harmony / Setting up OpenAPI/EdgeGrid for PS](https://collaborate.akamai.com/confluence/pages/viewpage.action?pageId=748278616)

## Usage

1. Clone the repository, using following command:

```bash
> git clone <git url>
> cd ps-terraform-templates/new-aap-configuration/
```

2. Inside the `./environments` folder is where you create/delete the subdirectories and files to support more environments if needed. Refer to the examples inside the `./environments` folder. If you only need a single environment just leave a single directory (you can name it "prod"). The environment name must also be used as prefix in the `tfvars` filename. In our example for "prod" the `tfvars` file will be `prod.tfvars`. Remove the .dist extension from the `tfvars` filenames you plan to reuse and specify the required values for the different parameters.

   You'll find additional instructions inside the example `tfvars` files.

3. Run the deployment script `../deploy.ps1`. This script is written in PowerShell and acts as an orchestrator for Terraform. It allows to perform individual save and activation actions, it handles the multi-environment directory and files to avoid overwriting the state file. A debug/log mode can also be enabled.

    A common flow is as follows (with "prod" as the environment):
    1. Save the changes only:
    ```bash
    pwsh deploy.ps1 aapasm -Env prod -Save -Notes "Some user user notes"
    ```

    2. Activate to staging:
    ```bash
    pwsh deploy.ps1 aapasm -Env prod -ActivateStaging
    ```

    3. Activate to production:
    ```bash
    pwsh deploy.ps1 aapasm -Env prod -ActivateProduction
    ```

    Options:
    * Add the `-Debug` option to the command to log all the Terraform actions in a file stored in the specific environment directory.
    * Add the `-Dry` option to the command to do a dry-run (nothing is applied).
    * You can delete all the resources when you don't need them. Keep in mind some resource can't be deleted in which cases the `terraform destroy` operation will fail as a consequence.
    ```bash
    pwsh deploy.ps1 aapasm -Env dev -Destroy
    ```

## Known Errors
### Client Reputation
You may see the following error during the first terraform execution because Client Reputation may not be available/ready in time. A 20s delay has been added to allow for Client Reputation to become available. However in some occurrences it may take longer. Instead of waiting for longer we retry automatically the apply if the error happens.

```hcl
│ Error: Provider produced inconsistent final plan
│
│ When expanding the plan for module.client-reputation[0].akamai_appsec_reputation_profile.web_attackers_high_threat to include new values learned so far during apply, provider
│ "registry.terraform.io/akamai/akamai" produced an invalid new value for .reputation_profile: was cty.StringVal(""), but now
│ cty.StringVal("{\"condition\":{\"atomicConditions\":[{\"checkIps\":\"connecting\",\"className\":\"NetworkListCondition\",\"index\":1,\"positiveMatch\":true,\"value\":[\"237955_DEVTFDEMOAPPSECREPUTATI\"]}],\"positiveMatch\":false},\"context\":\"WEBATCK\",\"name\":\"Web
│ Attackers (High Threat)\",\"sharedIpHandling\":\"NON_SHARED\",\"threshold\":9}").
│
│ This is a bug in the provider, which should be reported in the provider's own issue tracker.
```

### Destroy INTERNAL-SERVER-ERROR
This is probably the reason for another race condition with no further details. A retry happens automatically to overcome this error. The Destroy will succeed afterwards.

```hcl
│ Error: Title: Internal Server Error; Type: https://problems.luna.akamaiapis.net/appsec-configuration/error-types/INTERNAL-SERVER-ERROR; Detail: Error occurred while processing the request.
```

## Future Improvements

As of March 2025 API Definitions are not supported by the Akamai provider. As soon as it becomes available work will start to integrate it to this project.

# Usage
Basic usage of this module is as follows:

```hcl
module "example" {
  	 source  = "<module-location>"
  
	 # Required variables
  	 add_akamai_bot_header  = <bool>
  	 bot_academic_or_research  = <string>
  	 bot_aggressive_web_crawlers  = <string>
  	 bot_artificial_intelligence_ai  = <string>
  	 bot_browser_impersonator  = <string>
  	 bot_business_intelligence  = <string>
  	 bot_client_disabled_javascript_noscript_triggered  = <string>
  	 bot_cookie_integrity_failed  = <string>
  	 bot_declared_bots_keyword_match  = <string>
  	 bot_development_frameworks  = <string>
  	 bot_ecommerce_search_engine  = <string>
  	 bot_enterprise_data_aggregator  = <string>
  	 bot_financial_account_aggregator  = <string>
  	 bot_financial_services  = <string>
  	 bot_headless_browsersautomation_tools  = <string>
  	 bot_http_libraries  = <string>
  	 bot_impersonators_of_known_bots  = <string>
  	 bot_javascript_fingerprint_anomaly  = <string>
  	 bot_javascript_fingerprint_not_received  = <string>
  	 bot_job_search_engine  = <string>
  	 bot_media_or_entertainment_search  = <string>
  	 bot_news_aggregator  = <string>
  	 bot_online_advertising  = <string>
  	 bot_open_source_crawlersscraping_platforms  = <string>
  	 bot_rss_feed_reader  = <string>
  	 bot_seo_analytics_or_marketing  = <string>
  	 bot_session_validation  = <string>
  	 bot_site_monitoring_and_web_development  = <string>
  	 bot_social_media_or_blog  = <string>
  	 bot_web_archiver  = <string>
  	 bot_web_scraper_reputation  = <string>
  	 bot_web_search_engine  = <string>
  	 bot_web_services_libraries  = <string>
  	 botman_type  = <string>
  	 config_name  = <string>
  	 description  = <string>
  	 dos_origin_error_action  = <string>
  	 dos_page_view_requests_action  = <string>
  	 dos_post_page_requests_action  = <string>
  	 enable_active_detections  = <bool>
  	 enable_botman  = <bool>
  	 enable_browser_validation  = <bool>
  	 enable_client_reputation  = <bool>
  	 enable_ip_geo  = <bool>
  	 enable_malware  = <bool>
  	 enable_rate  = <bool>
  	 enable_request_constraints  = <bool>
  	 enable_slow_post  = <bool>
  	 enable_waf  = <bool>
  	 environment  = <string>
  	 group_name  = <string>
  	 hostnames  = <list(string)>
  	 inspection_size  = <number>
  	 penalty_box_action  = <string>
  	 policy_name  = <string>
  	 policy_prefix  = <string>
  	 remove_botman_cookies  = <bool>
  	 rep_dos_attackers_high  = <string>
  	 rep_dos_attackers_high_shared  = <string>
  	 rep_dos_attackers_low  = <string>
  	 rep_dos_attackers_low_shared  = <string>
  	 rep_scanning_tools_high  = <string>
  	 rep_scanning_tools_high_shared  = <string>
  	 rep_scanning_tools_low  = <string>
  	 rep_scanning_tools_low_shared  = <string>
  	 rep_web_attackers_high  = <string>
  	 rep_web_attackers_high_shared  = <string>
  	 rep_web_attackers_low  = <string>
  	 rep_web_attackers_low_shared  = <string>
  	 rep_web_scrapers_high  = <string>
  	 rep_web_scrapers_high_shared  = <string>
  	 rep_web_scrapers_low  = <string>
  	 rep_web_scrapers_low_shared  = <string>
  	 slow_post_action  = <string>
  	 third_party_proxy  = <bool>
  	 waf_cmd_action  = <string>
  	 waf_lfi_action  = <string>
  	 waf_platform_action  = <string>
  	 waf_policy_action  = <string>
  	 waf_protocol_action  = <string>
  	 waf_rfi_action  = <string>
  	 waf_sql_action  = <string>
  	 waf_wat_action  = <string>
  	 waf_xss_action  = <string>
  
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
  	 client_lists_geoblock  = <list(string)> | default: []
  	 client_lists_ipblock  = <list(string)> | default: []
  	 client_lists_ipblock_exception  = <list(string)> | default: []
  	 client_lists_pragmabypass  = <list(string)> | default: []
  	 client_lists_rcbypass  = <list(string)> | default: []
  	 client_lists_reputationbypass  = <list(string)> | default: []
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
| <a name="requirement_akamai"></a> [akamai](#requirement\_akamai) | ~> 9.0 |

## Resources

| Name | Type |
|------|------|
| [akamai_contract.contract](https://registry.terraform.io/providers/akamai/akamai/latest/docs/data-sources/contract) | data source |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_activate-security"></a> [activate-security](#module\_activate-security) | git::ssh://git@github.com/akamai/terraform-templates-modules.git//aap-asm/activate-security | v1.1.0 |
| <a name="module_botman"></a> [botman](#module\_botman) | git::ssh://git@github.com/akamai/terraform-templates-modules.git//aap-asm/bot-manager | v1.1.0 |
| <a name="module_client-lists"></a> [client-lists](#module\_client-lists) | git::ssh://git@github.com/akamai/terraform-templates-modules.git//aap/client-lists | v1.1.0 |
| <a name="module_client-reputation"></a> [client-reputation](#module\_client-reputation) | git::ssh://git@github.com/akamai/terraform-templates-modules.git//aap-asm/client-reputation | v1.1.0 |
| <a name="module_security"></a> [security](#module\_security) | git::ssh://git@github.com/akamai/terraform-templates-modules.git//aap-asm/security | v1.1.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_add_akamai_bot_header"></a> [add\_akamai\_bot\_header](#input\_add\_akamai\_bot\_header) | Adds a header named Akamai-Bot to bot request forwarded to the origin. The header contains details like: bot type, Botnet ID, action, detection method, and bot score details, if applicable | `bool` | n/a | yes |
| <a name="input_bot_academic_or_research"></a> [bot\_academic\_or\_research](#input\_bot\_academic\_or\_research) | Action for Akamai Bot Category: Academic or Research Bots | `string` | n/a | yes |
| <a name="input_bot_aggressive_web_crawlers"></a> [bot\_aggressive\_web\_crawlers](#input\_bot\_aggressive\_web\_crawlers) | Action for Bot Transparent Detections: Aggressive Web Crawlers | `string` | n/a | yes |
| <a name="input_bot_artificial_intelligence_ai"></a> [bot\_artificial\_intelligence\_ai](#input\_bot\_artificial\_intelligence\_ai) | Action for Akamai Bot Category: Artificial Intelligence (AI) Bots | `string` | n/a | yes |
| <a name="input_bot_browser_impersonator"></a> [bot\_browser\_impersonator](#input\_bot\_browser\_impersonator) | Action for Bot Transparent Detections: Browser Impersonator | `string` | n/a | yes |
| <a name="input_bot_business_intelligence"></a> [bot\_business\_intelligence](#input\_bot\_business\_intelligence) | Action for Akamai Bot Category: Business Intelligence Bots | `string` | n/a | yes |
| <a name="input_bot_client_disabled_javascript_noscript_triggered"></a> [bot\_client\_disabled\_javascript\_noscript\_triggered](#input\_bot\_client\_disabled\_javascript\_noscript\_triggered) | Bot Active Detections Actions: Client Disabled JavaScript (Noscript Triggered) | `string` | n/a | yes |
| <a name="input_bot_cookie_integrity_failed"></a> [bot\_cookie\_integrity\_failed](#input\_bot\_cookie\_integrity\_failed) | Bot Active Detections Actions: Cookie Integrity Failed | `string` | n/a | yes |
| <a name="input_bot_declared_bots_keyword_match"></a> [bot\_declared\_bots\_keyword\_match](#input\_bot\_declared\_bots\_keyword\_match) | Action for Bot Transparent Detections: Declared Bots (Keyword Match) | `string` | n/a | yes |
| <a name="input_bot_development_frameworks"></a> [bot\_development\_frameworks](#input\_bot\_development\_frameworks) | Action for Bot Transparent Detections: Development Frameworks | `string` | n/a | yes |
| <a name="input_bot_ecommerce_search_engine"></a> [bot\_ecommerce\_search\_engine](#input\_bot\_ecommerce\_search\_engine) | Action for Akamai Bot Category: E-Commerce Search Engine Bots | `string` | n/a | yes |
| <a name="input_bot_enterprise_data_aggregator"></a> [bot\_enterprise\_data\_aggregator](#input\_bot\_enterprise\_data\_aggregator) | Action for Akamai Bot Category: Enterprise Data Aggregator Bots | `string` | n/a | yes |
| <a name="input_bot_financial_account_aggregator"></a> [bot\_financial\_account\_aggregator](#input\_bot\_financial\_account\_aggregator) | Action for Akamai Bot Category: Financial Account Aggregator Bots | `string` | n/a | yes |
| <a name="input_bot_financial_services"></a> [bot\_financial\_services](#input\_bot\_financial\_services) | Action for Akamai Bot Category: Financial Services Bots | `string` | n/a | yes |
| <a name="input_bot_headless_browsersautomation_tools"></a> [bot\_headless\_browsersautomation\_tools](#input\_bot\_headless\_browsersautomation\_tools) | Action for Bot Transparent Detections: Headless Browsers/Automation Tools | `string` | n/a | yes |
| <a name="input_bot_http_libraries"></a> [bot\_http\_libraries](#input\_bot\_http\_libraries) | Action for Bot Transparent Detections: HTTP Libraries | `string` | n/a | yes |
| <a name="input_bot_impersonators_of_known_bots"></a> [bot\_impersonators\_of\_known\_bots](#input\_bot\_impersonators\_of\_known\_bots) | Action for Bot Transparent Detections: Impersonators of Known Bots | `string` | n/a | yes |
| <a name="input_bot_javascript_fingerprint_anomaly"></a> [bot\_javascript\_fingerprint\_anomaly](#input\_bot\_javascript\_fingerprint\_anomaly) | Bot Active Detections Actions: JavaScript Fingerprint Anomaly | `string` | n/a | yes |
| <a name="input_bot_javascript_fingerprint_not_received"></a> [bot\_javascript\_fingerprint\_not\_received](#input\_bot\_javascript\_fingerprint\_not\_received) | Bot Active Detections Actions: JavaScript Fingerprint Not Received | `string` | n/a | yes |
| <a name="input_bot_job_search_engine"></a> [bot\_job\_search\_engine](#input\_bot\_job\_search\_engine) | Action for Akamai Bot Category: Job Search Engine Bots | `string` | n/a | yes |
| <a name="input_bot_media_or_entertainment_search"></a> [bot\_media\_or\_entertainment\_search](#input\_bot\_media\_or\_entertainment\_search) | Action for Akamai Bot Category: Media or Entertainment Search Bots | `string` | n/a | yes |
| <a name="input_bot_news_aggregator"></a> [bot\_news\_aggregator](#input\_bot\_news\_aggregator) | Action for Akamai Bot Category: News Aggregator Bots | `string` | n/a | yes |
| <a name="input_bot_online_advertising"></a> [bot\_online\_advertising](#input\_bot\_online\_advertising) | Action for Akamai Bot Category: Online Advertising Bots | `string` | n/a | yes |
| <a name="input_bot_open_source_crawlersscraping_platforms"></a> [bot\_open\_source\_crawlersscraping\_platforms](#input\_bot\_open\_source\_crawlersscraping\_platforms) | Action for Bot Transparent Detections: Open Source Crawlers/Scraping Platforms | `string` | n/a | yes |
| <a name="input_bot_rss_feed_reader"></a> [bot\_rss\_feed\_reader](#input\_bot\_rss\_feed\_reader) | Action for Akamai Bot Category: RSS Feed Reader Bots | `string` | n/a | yes |
| <a name="input_bot_seo_analytics_or_marketing"></a> [bot\_seo\_analytics\_or\_marketing](#input\_bot\_seo\_analytics\_or\_marketing) | Action for Akamai Bot Category: SEO, Analytics or Marketing Bots | `string` | n/a | yes |
| <a name="input_bot_session_validation"></a> [bot\_session\_validation](#input\_bot\_session\_validation) | Bot Active Detections Actions: Session Validation | `string` | n/a | yes |
| <a name="input_bot_site_monitoring_and_web_development"></a> [bot\_site\_monitoring\_and\_web\_development](#input\_bot\_site\_monitoring\_and\_web\_development) | Action for Akamai Bot Category: Site Monitoring and Web Development Bots | `string` | n/a | yes |
| <a name="input_bot_social_media_or_blog"></a> [bot\_social\_media\_or\_blog](#input\_bot\_social\_media\_or\_blog) | Action for Akamai Bot Category: Social Media or Blog Bots | `string` | n/a | yes |
| <a name="input_bot_web_archiver"></a> [bot\_web\_archiver](#input\_bot\_web\_archiver) | Action for Akamai Bot Category: Web Archiver Bots | `string` | n/a | yes |
| <a name="input_bot_web_scraper_reputation"></a> [bot\_web\_scraper\_reputation](#input\_bot\_web\_scraper\_reputation) | Action for Bot Transparent Detections: Web Scraper Reputation | `string` | n/a | yes |
| <a name="input_bot_web_search_engine"></a> [bot\_web\_search\_engine](#input\_bot\_web\_search\_engine) | Action for Akamai Bot Category: Web Search Engine Bots | `string` | n/a | yes |
| <a name="input_bot_web_services_libraries"></a> [bot\_web\_services\_libraries](#input\_bot\_web\_services\_libraries) | Action for Bot Transparent Detections: Web Services Libraries | `string` | n/a | yes |
| <a name="input_botman_type"></a> [botman\_type](#input\_botman\_type) | Chose based on the available entitlement: BVM (Bot Visibility and Management) or BMS (Bot Management Standard) | `string` | n/a | yes |
| <a name="input_config_name"></a> [config\_name](#input\_config\_name) | Security configuration name | `string` | n/a | yes |
| <a name="input_description"></a> [description](#input\_description) | Security configuration description | `string` | n/a | yes |
| <a name="input_dos_origin_error_action"></a> [dos\_origin\_error\_action](#input\_dos\_origin\_error\_action) | Action for the Origin Error | `string` | n/a | yes |
| <a name="input_dos_page_view_requests_action"></a> [dos\_page\_view\_requests\_action](#input\_dos\_page\_view\_requests\_action) | Action for the Page View Requests | `string` | n/a | yes |
| <a name="input_dos_post_page_requests_action"></a> [dos\_post\_page\_requests\_action](#input\_dos\_post\_page\_requests\_action) | Action for the POST Page Requests | `string` | n/a | yes |
| <a name="input_enable_active_detections"></a> [enable\_active\_detections](#input\_enable\_active\_detections) | These methods interact with the requesting client using a combination of JavaScript and cookies to try to confirm that the request comes from a human using a real web browser | `bool` | n/a | yes |
| <a name="input_enable_botman"></a> [enable\_botman](#input\_enable\_botman) | Enable Bot Management Protection | `bool` | n/a | yes |
| <a name="input_enable_browser_validation"></a> [enable\_browser\_validation](#input\_enable\_browser\_validation) | Confirm that requests come from a browser. Enable use browser validation detection anywhere you expect browsers to visit the URL | `bool` | n/a | yes |
| <a name="input_enable_client_reputation"></a> [enable\_client\_reputation](#input\_enable\_client\_reputation) | Enable Client Reputation Protection | `bool` | n/a | yes |
| <a name="input_enable_ip_geo"></a> [enable\_ip\_geo](#input\_enable\_ip\_geo) | Enable IP/Geo Firewall Protection | `bool` | n/a | yes |
| <a name="input_enable_malware"></a> [enable\_malware](#input\_enable\_malware) | Enable Malware Protection | `bool` | n/a | yes |
| <a name="input_enable_rate"></a> [enable\_rate](#input\_enable\_rate) | Enable Rate Protection | `bool` | n/a | yes |
| <a name="input_enable_request_constraints"></a> [enable\_request\_constraints](#input\_enable\_request\_constraints) | Enable API Requests Constraints Protection | `bool` | n/a | yes |
| <a name="input_enable_slow_post"></a> [enable\_slow\_post](#input\_enable\_slow\_post) | Enable Slow POST Protection | `bool` | n/a | yes |
| <a name="input_enable_waf"></a> [enable\_waf](#input\_enable\_waf) | Enable Web Application Firewall Protection | `bool` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment (e.g. dev, qa, prod) | `string` | n/a | yes |
| <a name="input_group_name"></a> [group\_name](#input\_group\_name) | Akamai Group Name | `string` | n/a | yes |
| <a name="input_hostnames"></a> [hostnames](#input\_hostnames) | Hostnames to protect by the security config | `list(string)` | n/a | yes |
| <a name="input_inspection_size"></a> [inspection\_size](#input\_inspection\_size) | Request body inspection limit | `number` | n/a | yes |
| <a name="input_penalty_box_action"></a> [penalty\_box\_action](#input\_penalty\_box\_action) | Action for WAF Penalty Box | `string` | n/a | yes |
| <a name="input_policy_name"></a> [policy\_name](#input\_policy\_name) | Name for the security policy | `string` | n/a | yes |
| <a name="input_policy_prefix"></a> [policy\_prefix](#input\_policy\_prefix) | Prefix for the security policy | `string` | n/a | yes |
| <a name="input_remove_botman_cookies"></a> [remove\_botman\_cookies](#input\_remove\_botman\_cookies) | Remove Bot Manager cookies before sending request to origin | `bool` | n/a | yes |
| <a name="input_rep_dos_attackers_high"></a> [rep\_dos\_attackers\_high](#input\_rep\_dos\_attackers\_high) | Action for Reputation Profile: DoS Attackers (High Threat) NON-SHARED IPs | `string` | n/a | yes |
| <a name="input_rep_dos_attackers_high_shared"></a> [rep\_dos\_attackers\_high\_shared](#input\_rep\_dos\_attackers\_high\_shared) | Action for Reputation Profile: DoS Attackers (High Threat) SHARED IPs | `string` | n/a | yes |
| <a name="input_rep_dos_attackers_low"></a> [rep\_dos\_attackers\_low](#input\_rep\_dos\_attackers\_low) | Action for Reputation Profile: DoS Attackers (Low Threat) NON-SHARED IPs | `string` | n/a | yes |
| <a name="input_rep_dos_attackers_low_shared"></a> [rep\_dos\_attackers\_low\_shared](#input\_rep\_dos\_attackers\_low\_shared) | Action for Reputation Profile: DoS Attackers (Low Threat) SHARED IPs | `string` | n/a | yes |
| <a name="input_rep_scanning_tools_high"></a> [rep\_scanning\_tools\_high](#input\_rep\_scanning\_tools\_high) | Action for Reputation Profile: Scanning Tools (High Threat) NON-SHARED IPs | `string` | n/a | yes |
| <a name="input_rep_scanning_tools_high_shared"></a> [rep\_scanning\_tools\_high\_shared](#input\_rep\_scanning\_tools\_high\_shared) | Action for Reputation Profile: Scanning Tools (High Threat) SHARED IPs | `string` | n/a | yes |
| <a name="input_rep_scanning_tools_low"></a> [rep\_scanning\_tools\_low](#input\_rep\_scanning\_tools\_low) | Action for Reputation Profile: Scanning Tools (Low Threat) NON-SHARED IPs | `string` | n/a | yes |
| <a name="input_rep_scanning_tools_low_shared"></a> [rep\_scanning\_tools\_low\_shared](#input\_rep\_scanning\_tools\_low\_shared) | Action for Reputation Profile: Scanning Tools (Low Threat) SHARED IPs | `string` | n/a | yes |
| <a name="input_rep_web_attackers_high"></a> [rep\_web\_attackers\_high](#input\_rep\_web\_attackers\_high) | Action for Reputation Profile:  Web Attackers (High Threat) NON-SHARED IPs | `string` | n/a | yes |
| <a name="input_rep_web_attackers_high_shared"></a> [rep\_web\_attackers\_high\_shared](#input\_rep\_web\_attackers\_high\_shared) | Action for Reputation Profile:  Web Attackers (High Threat) SHARED IPs | `string` | n/a | yes |
| <a name="input_rep_web_attackers_low"></a> [rep\_web\_attackers\_low](#input\_rep\_web\_attackers\_low) | Action for Reputation Profile: Web Attackers (Low Threat) NON-SHARED IPs | `string` | n/a | yes |
| <a name="input_rep_web_attackers_low_shared"></a> [rep\_web\_attackers\_low\_shared](#input\_rep\_web\_attackers\_low\_shared) | Action for Reputation Profile: Web Attackers (Low Threat) SHARED IPs | `string` | n/a | yes |
| <a name="input_rep_web_scrapers_high"></a> [rep\_web\_scrapers\_high](#input\_rep\_web\_scrapers\_high) | Action for Reputation Profile: Web Scrapers (High Threat) NON-SHARED IPs | `string` | n/a | yes |
| <a name="input_rep_web_scrapers_high_shared"></a> [rep\_web\_scrapers\_high\_shared](#input\_rep\_web\_scrapers\_high\_shared) | Action for Reputation Profile: Web Scrapers (High Threat) SHARED IPs | `string` | n/a | yes |
| <a name="input_rep_web_scrapers_low"></a> [rep\_web\_scrapers\_low](#input\_rep\_web\_scrapers\_low) | Action for Reputation Profile: Web Scrapers (Low Threat) NON-SHARED IPs | `string` | n/a | yes |
| <a name="input_rep_web_scrapers_low_shared"></a> [rep\_web\_scrapers\_low\_shared](#input\_rep\_web\_scrapers\_low\_shared) | Action for Reputation Profile: Web Scrapers (Low Threat) SHARED IPs | `string` | n/a | yes |
| <a name="input_slow_post_action"></a> [slow\_post\_action](#input\_slow\_post\_action) | Action for the slow POST Protection | `string` | n/a | yes |
| <a name="input_third_party_proxy"></a> [third\_party\_proxy](#input\_third\_party\_proxy) | If you use a third-party proxy service between two Akamai Edge servers for things like A/B testing, content translation, or content adaption engines, turn this on to improve detection accuracy | `bool` | n/a | yes |
| <a name="input_waf_cmd_action"></a> [waf\_cmd\_action](#input\_waf\_cmd\_action) | Action for WAF attack group: Command Injection | `string` | n/a | yes |
| <a name="input_waf_lfi_action"></a> [waf\_lfi\_action](#input\_waf\_lfi\_action) | Action for WAF attack group: Local File Inclusion | `string` | n/a | yes |
| <a name="input_waf_platform_action"></a> [waf\_platform\_action](#input\_waf\_platform\_action) | Action for WAF attack group: Web Platform Attack | `string` | n/a | yes |
| <a name="input_waf_policy_action"></a> [waf\_policy\_action](#input\_waf\_policy\_action) | Action for WAF attack group: Web Policy Violation | `string` | n/a | yes |
| <a name="input_waf_protocol_action"></a> [waf\_protocol\_action](#input\_waf\_protocol\_action) | Action for WAF attack group: Web Protocol Attack | `string` | n/a | yes |
| <a name="input_waf_rfi_action"></a> [waf\_rfi\_action](#input\_waf\_rfi\_action) | Action for WAF attack group: Remote File Inclusion | `string` | n/a | yes |
| <a name="input_waf_sql_action"></a> [waf\_sql\_action](#input\_waf\_sql\_action) | Action for WAF attack group: SQL Injection | `string` | n/a | yes |
| <a name="input_waf_wat_action"></a> [waf\_wat\_action](#input\_waf\_wat\_action) | Action for WAF attack group: Web Attack Tool | `string` | n/a | yes |
| <a name="input_waf_xss_action"></a> [waf\_xss\_action](#input\_waf\_xss\_action) | Action for WAF attack group: Cross Site Scripting | `string` | n/a | yes |
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
| <a name="input_client_lists_geoblock"></a> [client\_lists\_geoblock](#input\_client\_lists\_geoblock) | ID(s) for the Geo Block Client List | `list(string)` | `[]` | no |
| <a name="input_client_lists_ipblock"></a> [client\_lists\_ipblock](#input\_client\_lists\_ipblock) | ID(s) for the IP Block Client List | `list(string)` | `[]` | no |
| <a name="input_client_lists_ipblock_exception"></a> [client\_lists\_ipblock\_exception](#input\_client\_lists\_ipblock\_exception) | ID(s) for the IP Block Exceptions Client List | `list(string)` | `[]` | no |
| <a name="input_client_lists_pragmabypass"></a> [client\_lists\_pragmabypass](#input\_client\_lists\_pragmabypass) | ID(s) for the Pragma Bypass Client List | `list(string)` | `[]` | no |
| <a name="input_client_lists_rcbypass"></a> [client\_lists\_rcbypass](#input\_client\_lists\_rcbypass) | ID(s) for the Rate Control Bypass Client List | `list(string)` | `[]` | no |
| <a name="input_client_lists_reputationbypass"></a> [client\_lists\_reputationbypass](#input\_client\_lists\_reputationbypass) | ID(s) for the Reputation Bypass Client List | `list(string)` | `[]` | no |
| <a name="input_client_lists_securitybypass"></a> [client\_lists\_securitybypass](#input\_client\_lists\_securitybypass) | ID(s) for the Security Bypass Client List | `list(string)` | `[]` | no |
| <a name="input_create_client_lists"></a> [create\_client\_lists](#input\_create\_client\_lists) | Request body inspection limit | `bool` | `true` | no |
| <a name="input_edgerc_path"></a> [edgerc\_path](#input\_edgerc\_path) | Specify path to the Akamai EdgeGrid authentication file that contains your Akamai API tokens. Typically ~/.edgerc. | `string` | `"~/.edgerc"` | no |
| <a name="input_edgerc_section"></a> [edgerc\_section](#input\_edgerc\_section) | Specify the section inside the edgerc file which can contain multiple sets of Akamai API tokens. Typically default. | `string` | `"default"` | no |
| <a name="input_emails"></a> [emails](#input\_emails) | List of emails for notifications | `list(string)` | <pre>[<br/>  "noreply@akamai.com"<br/>]</pre> | no |
| <a name="input_version_notes"></a> [version\_notes](#input\_version\_notes) | Property version notes. | `string` | `"Initial Config"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_config_id"></a> [config\_id](#output\_config\_id) | Security Configuration ID |
| <a name="output_security_policy_id"></a> [security\_policy\_id](#output\_security\_policy\_id) | Security Policy ID |
<!-- END_TF_DOCS -->