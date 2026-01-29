# -------------------------------------------------
# Environment variables (TF_VAR_*)
# -------------------------------------------------
# tflint-ignore: terraform_unused_declarations
variable "akamai_client_secret" {
  description = "Akamai client_secret API credential"
  type        = string
  default     = ""
}
# tflint-ignore: terraform_unused_declarations
variable "akamai_host" {
  description = "Akamai host API credential"
  type        = string
  default     = ""
}
# tflint-ignore: terraform_unused_declarations
variable "akamai_access_token" {
  description = "Akamai access_token API credential"
  type        = string
  default     = ""
}
# tflint-ignore: terraform_unused_declarations
variable "akamai_client_token" {
  description = "Akamai client_token API credential"
  type        = string
  default     = ""
}
# tflint-ignore: terraform_unused_declarations
variable "akamai_account_key" {
  description = "Akamai Account Key"
  type        = string
  default     = ""
}

# -------------------------------------------------
# Common Variables 
# -------------------------------------------------
variable "edgerc_path" {
  description = "Specify path to the Akamai EdgeGrid authentication file that contains your Akamai API tokens. Typically ~/.edgerc."
  type        = string
  default     = "~/.edgerc"
}

variable "edgerc_section" {
  description = "Specify the section inside the edgerc file which can contain multiple sets of Akamai API tokens. Typically default."
  type        = string
  default     = "default"
}

# tflint-ignore: terraform_unused_declarations
variable "environment" {
  description = "Environment (e.g. dev, qa, prod)"
  type        = string
}

variable "group_name" {
  description = "Akamai Group Name"
  type        = string
}

variable "config_name" {
  description = "Security configuration name"
  type        = string
}

variable "description" {
  description = "Security configuration description"
  type        = string
}

variable "version_notes" {
  description = "Property version notes."
  type        = string
  default     = "Initial Config"
}

variable "hostnames" {
  description = "Hostnames to protect by the security config"
  type        = list(string)

  validation {
    condition = alltrue([
      for h in var.hostnames : h == lower(h)
    ])
    error_message = "All hostnames must be lowercase."
  }
}

variable "emails" {
  description = "List of emails for notifications"
  type        = list(string)
  default     = ["noreply@akamai.com"]
}

# tflint-ignore: terraform_unused_declarations
variable "activation_notes" {
  description = "Notes for the activation"
  type        = string
  default     = "Activated by Terraform"
}

variable "activate_to_staging" {
  description = "Set to true to directly activate on the staging network."
  type        = bool
  default     = false
}

variable "activate_to_production" {
  description = "Set to true to directly activate on the production network."
  type        = bool
  default     = false
}

variable "activation_to_staging_exists" {
  description = "Do not modify. Flag used together with the logic in the activation resources for the initial activation to staging."
  type        = bool
  default     = false
}

variable "activation_to_production_exists" {
  description = "Do not modify. Flag used together with the logic in the activation resources for the initial activation to production."
  type        = bool
  default     = false
}

# -------------------------------------------------
# Advanced settings
# -------------------------------------------------
variable "inspection_size" {
  description = "Request body inspection limit"
  type        = number
}

# -------------------------------------------------
# Protections
# -------------------------------------------------
variable "enable_waf" {
  description = "Enable Web Application Firewall Protection"
  type        = bool
}

variable "enable_request_constraints" {
  description = "Enable API Requests Constraints Protection"
  type        = bool
}

variable "enable_ip_geo" {
  description = "Enable IP/Geo Firewall Protection"
  type        = bool
}

variable "enable_malware" {
  description = "Enable Malware Protection"
  type        = bool
}

variable "enable_rate" {
  description = "Enable Rate Protection"
  type        = bool
}

variable "enable_client_reputation" {
  description = "Enable Client Reputation Protection"
  type        = bool
}

variable "enable_slow_post" {
  description = "Enable Slow POST Protection"
  type        = bool
}

variable "enable_botman" {
  description = "Enable Bot Management Protection"
  type        = bool
}

# -------------------------------------------------
# Client Lists
# -------------------------------------------------
variable "create_client_lists" {
  description = "Request body inspection limit"
  type        = bool
  default     = true
}

# IP/Geo Firewall
variable "client_lists_ipblock" {
  description = "ID(s) for the IP Block Client List"
  type        = list(string)
  default     = []
}

variable "client_lists_ipblock_exception" {
  description = "ID(s) for the IP Block Exceptions Client List"
  type        = list(string)
  default     = []
}

variable "client_lists_geoblock" {
  description = "ID(s) for the Geo Block Client List"
  type        = list(string)
  default     = []
}

# Bypass Lists
variable "client_lists_securitybypass" {
  description = "ID(s) for the Security Bypass Client List"
  type        = list(string)
  default     = []
}

variable "client_lists_rcbypass" {
  description = "ID(s) for the Rate Control Bypass Client List"
  type        = list(string)
  default     = []
}

variable "client_lists_pragmabypass" {
  description = "ID(s) for the Pragma Bypass Client List"
  type        = list(string)
  default     = []
}

variable "client_lists_reputationbypass" {
  description = "ID(s) for the Reputation Bypass Client List"
  type        = list(string)
  default     = []
}

# -------------------------------------------------
# Specifics for the Security Policy
# -------------------------------------------------
# Security Policy Details
variable "policy_name" {
  description = "Name for the security policy"
  type        = string
}

variable "policy_prefix" {
  description = "Prefix for the security policy"
  type        = string
}

# Dos Protection
variable "dos_origin_error_action" {
  description = "Action for the Origin Error"
  type        = string
}

variable "dos_post_page_requests_action" {
  description = "Action for the POST Page Requests"
  type        = string
}

variable "dos_page_view_requests_action" {
  description = "Action for the Page View Requests"
  type        = string
}

variable "slow_post_action" {
  description = "Action for the slow POST Protection"
  type        = string
}

# Web Application Firewall (WAF) Actions
variable "waf_policy_action" {
  description = "Action for WAF attack group: Web Policy Violation"
  type        = string
}

variable "waf_wat_action" {
  description = "Action for WAF attack group: Web Attack Tool"
  type        = string
}

variable "waf_protocol_action" {
  description = "Action for WAF attack group: Web Protocol Attack"
  type        = string
}

variable "waf_sql_action" {
  description = "Action for WAF attack group: SQL Injection"
  type        = string
}

variable "waf_xss_action" {
  description = "Action for WAF attack group: Cross Site Scripting"
  type        = string
}

variable "waf_cmd_action" {
  description = "Action for WAF attack group: Command Injection"
  type        = string
}

variable "waf_lfi_action" {
  description = "Action for WAF attack group: Local File Inclusion"
  type        = string
}

variable "waf_rfi_action" {
  description = "Action for WAF attack group: Remote File Inclusion"
  type        = string
}

variable "waf_platform_action" {
  description = "Action for WAF attack group: Web Platform Attack"
  type        = string
}

variable "penalty_box_action" {
  description = "Action for WAF Penalty Box"
  type        = string
}

# Client Reputation Actions
variable "rep_web_attackers_high" {
  description = "Action for Reputation Profile:  Web Attackers (High Threat) NON-SHARED IPs"
  type        = string
}

variable "rep_web_attackers_high_shared" {
  description = "Action for Reputation Profile:  Web Attackers (High Threat) SHARED IPs"
  type        = string
}

variable "rep_web_attackers_low" {
  description = "Action for Reputation Profile: Web Attackers (Low Threat) NON-SHARED IPs"
  type        = string
}

variable "rep_web_attackers_low_shared" {
  description = "Action for Reputation Profile: Web Attackers (Low Threat) SHARED IPs"
  type        = string
}

variable "rep_dos_attackers_high" {
  description = "Action for Reputation Profile: DoS Attackers (High Threat) NON-SHARED IPs"
  type        = string
}

variable "rep_dos_attackers_high_shared" {
  description = "Action for Reputation Profile: DoS Attackers (High Threat) SHARED IPs"
  type        = string
}

variable "rep_dos_attackers_low" {
  description = "Action for Reputation Profile: DoS Attackers (Low Threat) NON-SHARED IPs"
  type        = string
}

variable "rep_dos_attackers_low_shared" {
  description = "Action for Reputation Profile: DoS Attackers (Low Threat) SHARED IPs"
  type        = string
}

variable "rep_scanning_tools_high" {
  description = "Action for Reputation Profile: Scanning Tools (High Threat) NON-SHARED IPs"
  type        = string
}

variable "rep_scanning_tools_high_shared" {
  description = "Action for Reputation Profile: Scanning Tools (High Threat) SHARED IPs"
  type        = string
}

variable "rep_scanning_tools_low" {
  description = "Action for Reputation Profile: Scanning Tools (Low Threat) NON-SHARED IPs"
  type        = string
}

variable "rep_scanning_tools_low_shared" {
  description = "Action for Reputation Profile: Scanning Tools (Low Threat) SHARED IPs"
  type        = string
}

variable "rep_web_scrapers_high" {
  description = "Action for Reputation Profile: Web Scrapers (High Threat) NON-SHARED IPs"
  type        = string
}

variable "rep_web_scrapers_high_shared" {
  description = "Action for Reputation Profile: Web Scrapers (High Threat) SHARED IPs"
  type        = string
}

variable "rep_web_scrapers_low" {
  description = "Action for Reputation Profile: Web Scrapers (Low Threat) NON-SHARED IPs"
  type        = string
}

variable "rep_web_scrapers_low_shared" {
  description = "Action for Reputation Profile: Web Scrapers (Low Threat) SHARED IPs"
  type        = string
}

# Bot Manager General Settings
variable "botman_type" {
  description = "Chose based on the available entitlement: BVM (Bot Visibility and Management) or BMS (Bot Management Standard)"
  type        = string
  validation {
    condition     = can(index(["bvm", "bms"], var.botman_type))
    error_message = "Invalid value for Botman Type. Allowed values are bvm or bms."
  }
}

variable "add_akamai_bot_header" {
  description = "Adds a header named Akamai-Bot to bot request forwarded to the origin. The header contains details like: bot type, Botnet ID, action, detection method, and bot score details, if applicable"
  type        = bool
}

variable "enable_active_detections" {
  description = "These methods interact with the requesting client using a combination of JavaScript and cookies to try to confirm that the request comes from a human using a real web browser"
  type        = bool
}

variable "enable_browser_validation" {
  description = "Confirm that requests come from a browser. Enable use browser validation detection anywhere you expect browsers to visit the URL"
  type        = bool
}

variable "remove_botman_cookies" {
  description = "Remove Bot Manager cookies before sending request to origin"
  type        = bool
}

variable "third_party_proxy" {
  description = "If you use a third-party proxy service between two Akamai Edge servers for things like A/B testing, content translation, or content adaption engines, turn this on to improve detection accuracy"
  type        = bool
}

# Bot Category Actions
variable "bot_site_monitoring_and_web_development" {
  description = "Action for Akamai Bot Category: Site Monitoring and Web Development Bots"
  type        = string
}

variable "bot_academic_or_research" {
  description = "Action for Akamai Bot Category: Academic or Research Bots"
  type        = string
}

variable "bot_job_search_engine" {
  description = "Action for Akamai Bot Category: Job Search Engine Bots"
  type        = string
}

variable "bot_artificial_intelligence_ai" {
  description = "Action for Akamai Bot Category: Artificial Intelligence (AI) Bots"
  type        = string
}

variable "bot_online_advertising" {
  description = "Action for Akamai Bot Category: Online Advertising Bots"
  type        = string
}

variable "bot_ecommerce_search_engine" {
  description = "Action for Akamai Bot Category: E-Commerce Search Engine Bots"
  type        = string
}

variable "bot_web_search_engine" {
  description = "Action for Akamai Bot Category: Web Search Engine Bots"
  type        = string
}

variable "bot_enterprise_data_aggregator" {
  description = "Action for Akamai Bot Category: Enterprise Data Aggregator Bots"
  type        = string
}

variable "bot_financial_services" {
  description = "Action for Akamai Bot Category: Financial Services Bots"
  type        = string
}

variable "bot_social_media_or_blog" {
  description = "Action for Akamai Bot Category: Social Media or Blog Bots"
  type        = string
}

variable "bot_web_archiver" {
  description = "Action for Akamai Bot Category: Web Archiver Bots"
  type        = string
}

variable "bot_business_intelligence" {
  description = "Action for Akamai Bot Category: Business Intelligence Bots"
  type        = string
}

variable "bot_news_aggregator" {
  description = "Action for Akamai Bot Category: News Aggregator Bots"
  type        = string
}

variable "bot_rss_feed_reader" {
  description = "Action for Akamai Bot Category: RSS Feed Reader Bots"
  type        = string
}

variable "bot_financial_account_aggregator" {
  description = "Action for Akamai Bot Category: Financial Account Aggregator Bots"
  type        = string
}

variable "bot_media_or_entertainment_search" {
  description = "Action for Akamai Bot Category: Media or Entertainment Search Bots"
  type        = string
}

variable "bot_seo_analytics_or_marketing" {
  description = "Action for Akamai Bot Category: SEO, Analytics or Marketing Bots"
  type        = string
}

# Bot Transparent Detections Actions
variable "bot_impersonators_of_known_bots" {
  description = "Action for Bot Transparent Detections: Impersonators of Known Bots "
  type        = string
}

variable "bot_development_frameworks" {
  description = "Action for Bot Transparent Detections: Development Frameworks "
  type        = string
}

variable "bot_http_libraries" {
  description = "Action for Bot Transparent Detections: HTTP Libraries "
  type        = string
}

variable "bot_web_services_libraries" {
  description = "Action for Bot Transparent Detections: Web Services Libraries "
  type        = string
}

variable "bot_open_source_crawlersscraping_platforms" {
  description = "Action for Bot Transparent Detections: Open Source Crawlers/Scraping Platforms "
  type        = string
}

variable "bot_headless_browsersautomation_tools" {
  description = "Action for Bot Transparent Detections: Headless Browsers/Automation Tools"
  type        = string
}

variable "bot_declared_bots_keyword_match" {
  description = "Action for Bot Transparent Detections: Declared Bots (Keyword Match) "
  type        = string
}

variable "bot_aggressive_web_crawlers" {
  description = "Action for Bot Transparent Detections: Aggressive Web Crawlers"
  type        = string
}

variable "bot_browser_impersonator" {
  description = "Action for Bot Transparent Detections: Browser Impersonator"
  type        = string
}

variable "bot_web_scraper_reputation" {
  description = "Action for Bot Transparent Detections: Web Scraper Reputation "
  type        = string
}

# Bot Active Detections Actions
variable "bot_cookie_integrity_failed" {
  description = "Bot Active Detections Actions: Cookie Integrity Failed "
  type        = string
}

variable "bot_session_validation" {
  description = "Bot Active Detections Actions: Session Validation "
  type        = string
}

variable "bot_client_disabled_javascript_noscript_triggered" {
  description = "Bot Active Detections Actions: Client Disabled JavaScript (Noscript Triggered)"
  type        = string
}

variable "bot_javascript_fingerprint_anomaly" {
  description = "Bot Active Detections Actions: JavaScript Fingerprint Anomaly"
  type        = string
}

variable "bot_javascript_fingerprint_not_received" {
  description = "Bot Active Detections Actions: JavaScript Fingerprint Not Received"
  type        = string
}