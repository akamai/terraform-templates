variable "domain_validation_entries" {
  description = "A list of objects with hostnames, domains, or wildcards to DOM validate"
  type = list(object({
    domain_name       = string
    validation_scope  = string
    validation_method = optional(string, "DNS_TXT") # Default to "DNS_TXT"
  }))
  default = []
  validation {
    condition     = length(var.domain_validation_entries) <= 1000
    error_message = "Maximum of 1000 domain validation entries allowed."
  }
  validation {
    condition = length(distinct([
      for entry in var.domain_validation_entries : lower(entry.domain_name)
    ])) == length(var.domain_validation_entries)
    error_message = "domain_validation_entries must not contain duplicate domain names."
  }
  validation {
    condition = (
      alltrue([
        for entry in var.domain_validation_entries : contains(["HOST", "DOMAIN", "WILDCARD"], upper(entry.validation_scope))
      ])
      && alltrue([
        for entry in var.domain_validation_entries : (
          upper(entry.validation_scope) == "HOST" ? (
            !can(regex("^\\*\\.", entry.domain_name))
            && can(regex("^[^.]+\\..+$", entry.domain_name))
            ) : upper(entry.validation_scope) == "WILDCARD" ? (
            can(regex("^\\*\\.[^.]+\\.[^.]+$", entry.domain_name))
            ) : (
            !can(regex("^\\*\\.", entry.domain_name))
            && can(regex("^[^.]+\\..+$", entry.domain_name))
          )
        )
      ])
      && alltrue([
        for entry in var.domain_validation_entries : upper(entry.validation_scope) != "HOST" ? true : alltrue([
          for domain_name in [
            for domain_entry in var.domain_validation_entries : lower(domain_entry.domain_name) if upper(domain_entry.validation_scope) == "DOMAIN"
          ] : lower(entry.domain_name) != domain_name && !endswith(lower(entry.domain_name), format(".%s", domain_name))
        ])
      ])
      && alltrue([
         for entry in var.domain_validation_entries : (
           contains(["DNS_TXT", "DNS_CNAME", "HTTP"], entry.validation_method)
           && (entry.validation_method != "HTTP" || upper(entry.validation_scope) == "HOST")
         )
       ])
     )
    error_message = <<-EOT
      validation_scope must be HOST, DOMAIN, or WILDCARD;
      HOST entries are exact names;
      WILDCARD entries start with '*.' and cover only first-level subdomains of the base domain;
      DOMAIN entries cover the apex and all subdomains;
      HOST entries cannot overlap with DOMAIN entries (e.g., host.example.com conflicts with example.com);
      validation_method must be one of: DNS_TXT, DNS_CNAME, HTTP; HTTP is only valid for HOST entries.
    EOT
  }
}

variable "enable_validation" {
  description = "Set to true to enable domain validation"
  type        = bool
  default     = false
}

variable "edgerc_path" {
  description = "Path to the .edgerc file"
  type        = string
  default     = "~/.edgerc"
}

variable "edgerc_section" {
  description = "Section in the .edgerc file"
  type        = string
}

variable "domain_search_entries" {
  description = "List of domains to search validation status for, independent of domain_validation_entries"
  type = list(object({
    domain_name      = string
    validation_scope = string
  }))
  default = []
}