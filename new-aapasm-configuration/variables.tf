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
# Client Lists
# -------------------------------------------------
variable "create_client_lists" {
  description = "Set to true to create new client lists, false to use existing IDs"
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

variable "client_lists_asnblock" {
  description = "ID(s) for the ASN Block Client List"
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

# -------------------------------------------------
# Policy Defaults
# -------------------------------------------------
variable "policy_defaults" {
  description = "Default values for all security policies. Each policy inherits these unless it provides its own override."
  type = object({
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
  })
}

# -------------------------------------------------
# Policies
# -------------------------------------------------
variable "policies" {
  description = "Map of security policies to create. Each key is a stable identifier (renaming destroys/recreates). Required per entry: policy_name, policy_prefix, hostnames. All other fields are optional and override policy_defaults when set."
  type = map(object({
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
  }))

  validation {
    condition     = length(var.policies) > 0
    error_message = "At least one policy must be defined."
  }

  validation {
    condition = alltrue([
      for p in values(var.policies) : alltrue([for h in p.hostnames : h == lower(h)])
    ])
    error_message = "All hostnames in policies must be lowercase."
  }
}
