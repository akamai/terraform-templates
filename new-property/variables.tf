## ----------------------------------------------------------------------------
## EdgeGrid
## ----------------------------------------------------------------------------

variable "edgerc_path" {
  description = <<EOD
    Path to the .edgerc file.
  EOD
  type        = string
  default     = "~/.edgerc"
}

variable "edgerc_section" {
  description = <<EOD
    Section in the .edgerc file.

    For professional services, it is recommended to create a new section for
    each account managed.
  EOD
  type        = string
}

## ----------------------------------------------------------------------------
## Scope
## ----------------------------------------------------------------------------

variable "contract_id" {
  description = "Contract ID for property/config creation"
  type        = string
}

variable "group_id" {
  description = "Group ID for property/config creation."
  type        = string
}

## ----------------------------------------------------------------------------
## Property
## ----------------------------------------------------------------------------

variable "product_id" {
  description = "Property Manager product. [ION - Fresca]"
  type        = string
  default     = "Site_Accel"
}

variable "name" {
  description = "Property name."
  type        = string
}

variable "version_notes" {
  description = "Property version notes."
  type        = string
  default     = "Initial Config"
}

variable "hostnames" {
  description = "List of hostnames."
  type        = list(string)

  validation {
    condition = alltrue([
      for h in var.hostnames : h == lower(h)
    ])
    error_message = "All hostnames must be lowercase."
  }
}

variable "etls" {
  description = "Boolean to switch between Enhanced and Standard TLS modes"
  type        = bool
}

variable "default_origin" {
  description = "Default origin server for all properties"
  type        = string
}

variable "forward_host_header" {
  description = "Host header to be forwarded to the origin server. Possible fixed values are ORIGIN_HOSTNAME or REQUEST_HOST_HEADER. But the user can also select any host header they would like to use as a custom value."
  type        = string
  default     = "REQUEST_HOST_HEADER"
}

variable "additional_origins" {
  description = "Additional origins for the property. For now the match is only by hostname. The field forward_host_header allows specifying a custom host header for each additional origin.Possible fixed values are ORIGIN_HOSTNAME or REQUEST_HOST_HEADER. But the user can also select any host header they would like to use as a custom value."
  type = map(object({
    origin_name         = string
    forward_host_header = string
    hostname_match      = list(string)
    path_match          = list(string)
  }))
}

variable "sure_route_test_object" {
  description = "Test object path for SureRoute"
  type        = string
  default     = "/akamai/testobject.html"
}

variable "td_region" {
  description = <<-EOD
    Region (map) for Tiered Distribution behaviour. Only applies if network is Standard TLS.
    Options are: CH2, CHAPAC, CHEU2, CHEUS2, CHWUS2, CHCUS2, CHAUS
  EOD
  type        = string
  default     = "CH2"
}

variable "enable_mPulse" {
  description = "Boolean to decide whether to inject the mpulse behavior"
  type        = bool
  default     = true
}

## ----------------------------------------------------------------------------
## Activation
## ----------------------------------------------------------------------------

variable "emails" {
  description = "List or emails for notifications"
  type        = list(string)
  validation {
    condition     = length(var.emails) > 0
    error_message = "At least one email should be provided"
  }
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

variable "noncompliance_reason" {
  type        = list(string)
  description = "Allowed values for noncompliance_reason are \"NO_PRODUCTION_TRAFFIC\", \"EMERGENCY\", \"NONE\". (OR null for the customer, as None will require the complaince block)"
  default     = []
  validation {
    condition = (
      length(var.noncompliance_reason) == 0 ||
      (
        length(var.noncompliance_reason) == 1 &&
        (
          contains(var.noncompliance_reason, "EMERGENCY") ||
          contains(var.noncompliance_reason, "OTHER") ||
          contains(var.noncompliance_reason, "NO_PRODUCTION_TRAFFIC") ||
          contains(var.noncompliance_reason, "NONE")
        )
      )
    )
    error_message = "Allowed values for noncompliance_reason are \"NO_PRODUCTION_TRAFFIC\", \"EMERGENCY\", \"NONE\", \"OTHER\"."
  }
}

variable "ticket_id" {
  type        = string
  description = "Identifies the ticket that describes the need for the activation"
  default     = null
}

# tflint-ignore: terraform_unused_declarations
variable "other_noncompliance_reason" {
  type        = string
  description = "Describes the reason why the activation must occur immediately, out of compliance with the standard procedure"
  default     = null
}

variable "peer_reviewed_by" {
  type        = string
  description = "Email address of the peer who performed the review"
  default     = null
}

variable "customer_email" {
  type        = string
  description = "Email address of the customer that acknowledged, tested and accepted the change"
  default     = null
}

variable "unit_tested" {
  type        = bool
  description = "Whether the metadata to activate has been fully tested"
  default     = null
}

variable "activation_notes" {
  description = "Activation notes. Leave default value until DXE-2373 is resolved, unless you know what you are doing."
  type        = string
  default     = "activated with terraform"
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



## ----------------------------------------------------------------------------
## CP Code
## ----------------------------------------------------------------------------
variable "default_cpcode" {
  description = "Boolean to enable the default CP Code for all properties. If false, the CP Code must be specified in the property definition."
  type        = bool
  default     = false
}

variable "cpcode_name" {
  description = "Default CP Code name. Will be the property name (var.name) if null."
  type        = string
  default     = null
}

## ----------------------------------------------------------------------------
## Certificate
## ----------------------------------------------------------------------------

variable "secure_by_default" {
  description = <<-EOD
    Secure by default. Set to true to use the DEFAULT certificate provisioning type.

    This is the easiest for automation, because Akamai takes care of provisioning the certificate
    using a Let's Encrypt DV SAN in a fully managed way.

    If the customer requires an OV SAN, or Secure by Default is inapplicable for whatever
    other reason, set this to false.
  EOD
  type        = bool
  default     = true
}

variable "certificate_id" {
  description = <<-EOD
    Certificate enrollment id. Only applicable if enhanced_tls is true, and secure_by_default
    is false.

    Can be retrieved using AkamaiPowershell or the Akamai CPS CLI.
  EOD
  type        = number
  default     = null
}

## ----------------------------------------------------------------------------
## EdgeHostname
## ----------------------------------------------------------------------------

variable "ehn_domain" {
  description = <<-EOD
    EdgeHostname domain, e.g. edgesuite.net or edgekey.net. Will default to one or
    the other, based on the value of etls variable.
  EOD
  type        = string
  default     = null
}

variable "ip_behavior" {
  description = <<-EOD
    EdgeHostname IP behaviour.Possible values are IPV4 or IPV6_COMPLIANCE.
  EOD
  type        = string
  default     = "IPV6_COMPLIANCE"

  validation {
    condition     = length(regexall("^(IPV4|IPV6_COMPLIANCE)$", var.ip_behavior)) > 0
    error_message = "ERROR: Valid types are IPV4 or IPV6_COMPLIANCE."
  }
}