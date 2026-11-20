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
  description = "Contract ID for property/config creation."
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
  description = "Property Manager product. [AMD - Adaptive Media Delivery]"
  type        = string
  default     = "prd_Adaptive_Media_Delivery"
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
  description = <<-EOT
    List of hostnames, e.g. ["www.example.com", "media.example.com"].
    For SBD with etls=true, Akamai provisions the edgekey.net hostname
    automatically. For SBD with etls=false, EDGESUITE, and EDGEKEY, each
    entry is your own domain and its edge hostname is created as needed. For
    AKAMAIZED_HOSTNAME, each entry is just a label (e.g. "abm-template-test")
    -- the .akamaized.net suffix is appended automatically and used as both
    cname_from and cname_to.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.hostnames) > 0 && length(distinct(var.hostnames)) == length(var.hostnames)
    error_message = "hostnames must contain at least one unique hostname."
  }

  validation {
    condition = alltrue([
      for h in var.hostnames : (
        var.edge_hostname_type == "AKAMAIZED_HOSTNAME"
        ? length(h) >= 4 && length(h) <= 63 && can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", h))
        : length(h) <= 253 && alltrue([
          for label in split(".", h) :
          length(label) >= 1 && length(label) <= 63 && can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", label))
        ])
      )
    ])
    error_message = "hostnames must be lowercase valid DNS names; AKAMAIZED_HOSTNAME values must be 4-63 character labels."
  }
}

variable "edge_hostname_type" {
  description = "Edge hostname mode: SBD (Secure By Default, no cert needed), EDGESUITE (aka Freeflow, <hostname>.edgesuite.net), EDGEKEY (aka ESSL, <hostname>.edgekey.net), or AKAMAIZED_HOSTNAME (<label>.akamaized.net, hostname and edge hostname are identical)."
  type        = string
  default     = "SBD"

  validation {
    condition     = contains(["SBD", "EDGESUITE", "EDGEKEY", "AKAMAIZED_HOSTNAME"], var.edge_hostname_type)
    error_message = "edge_hostname_type must be one of SBD, EDGESUITE, EDGEKEY, AKAMAIZED_HOSTNAME."
  }

  validation {
    condition = (
      var.edge_hostname_type == "SBD" ||
      (var.edge_hostname_type == "EDGESUITE" && !var.etls) ||
      (var.edge_hostname_type == "EDGEKEY" && var.etls) ||
      var.edge_hostname_type == "AKAMAIZED_HOSTNAME"
    )
    error_message = "Use etls=false with EDGESUITE and etls=true with EDGEKEY. SBD accepts either value. For AKAMAIZED_HOSTNAME, set it to false."
  }
}

variable "certificate_id" {
  description = "CPS certificate enrollment ID. Required only when edge_hostname_type is EDGEKEY."
  type        = number
  default     = null

  validation {
    condition     = var.edge_hostname_type != "EDGEKEY" || var.certificate_id != null
    error_message = "certificate_id is required when edge_hostname_type is EDGEKEY."
  }
}

variable "ip_behavior" {
  description = "IP version behavior for the edge hostname: IPV4 or IPV6_COMPLIANCE."
  type        = string
  default     = "IPV4"

  validation {
    condition     = contains(["IPV4", "IPV6_COMPLIANCE"], var.ip_behavior)
    error_message = "ip_behavior must be IPV4 or IPV6_COMPLIANCE."
  }
}

variable "etls" {
  description = "Security profile selector: SBD uses edgekey.net when true or edgesuite.net when false; EDGEKEY requires true; EDGESUITE requires false. For AKAMAIZED_HOSTNAME, set it to false."
  type        = bool
  default     = true
}

variable "default_origin" {
  description = "Origin server for the property."
  type        = string
}

variable "additional_origins" {
  description = "Optional additional origins selected by hostname and/or path criteria."
  type = map(object({
    origin_name         = string
    forward_host_header = string
    hostname_match      = list(string)
    path_match          = list(string)
  }))
  default = {}
}

variable "forward_host_header" {
  description = "Value forwarded as the Host header to origin. Use REQUEST_HOST_HEADER, ORIGIN_HOSTNAME, or a custom hostname."
  type        = string
  default     = "REQUEST_HOST_HEADER"
}

variable "http2_enabled" {
  description = "Enable HTTP/2 between edge and origin."
  type        = bool
  default     = true
}

variable "min_tls_version" {
  description = "Minimum TLS version for edge-to-origin connections."
  type        = string
  default     = "DYNAMIC"
}

variable "verification_mode" {
  description = "Origin certificate verification mode."
  type        = string
  default     = "PLATFORM_SETTINGS"
}

## ----------------------------------------------------------------------------
## AMD behaviors
## ----------------------------------------------------------------------------

variable "segmented_media_optimization_behavior" {
  description = "Segmented media optimization mode: ON_DEMAND or LIVE."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "LIVE"], var.segmented_media_optimization_behavior)
    error_message = "segmented_media_optimization_behavior must be ON_DEMAND or LIVE."
  }
}

variable "origin_authentication_method" {
  description = "Authentication method used to reach the origin."
  type        = string
  default     = "AUTOMATIC"
}

variable "origin_country" {
  description = "Country of the origin, used for origin_characteristics. UNKNOWN if not applicable."
  type        = string
  default     = "UNKNOWN"
}

variable "client_country" {
  description = "Country used for client_characteristics. UNKNOWN if not applicable."
  type        = string
  default     = "UNKNOWN"
}

variable "content_catalog_size" {
  description = "Approximate size of the media catalog served by this property."
  type        = string
  default     = "UNKNOWN"
}

variable "content_type" {
  description = "Primary content resolution/type served (e.g. HD, SD, 4K)."
  type        = string
  default     = "HD"
}

variable "content_popularity_distribution" {
  description = "Expected popularity distribution of content requests."
  type        = string
  default     = "UNKNOWN"
}

variable "enable_dash" {
  description = "Whether DASH is a delivery format for this property."
  type        = bool
  default     = true
}

variable "enable_hds" {
  description = "Whether HDS is a delivery format for this property."
  type        = bool
  default     = true
}

variable "enable_hls" {
  description = "Whether HLS is a delivery format for this property."
  type        = bool
  default     = true
}

variable "enable_smooth" {
  description = "Whether Smooth Streaming is a delivery format for this property."
  type        = bool
  default     = true
}

variable "segment_duration_dash" {
  description = "Segment duration for DASH content."
  type        = string
  default     = "SEGMENT_DURATION_6S"
}

variable "segment_duration_hds" {
  description = "Segment duration for HDS content."
  type        = string
  default     = "SEGMENT_DURATION_6S"
}

variable "segment_duration_hls" {
  description = "Segment duration for HLS content."
  type        = string
  default     = "SEGMENT_DURATION_10S"
}

variable "segment_duration_smooth" {
  description = "Segment duration for Smooth Streaming content."
  type        = string
  default     = "SEGMENT_DURATION_2S"
}

variable "cache_key_query_params_behavior" {
  description = "How query parameters are treated in the cache key."
  type        = string
  default     = "IGNORE_ALL"
}

variable "enable_dynamic_throughput_optimization" {
  description = "Enable dynamic throughput optimization for adaptive bitrate delivery."
  type        = bool
  default     = true
}

variable "enable_http3" {
  description = "Enable HTTP/3 (QUIC) support."
  type        = bool
  default     = true
}

variable "enable_segmented_content_protection" {
  description = "Master toggle for segmented content protection (token auth, media encryption)."
  type        = bool
  default     = false
}

variable "dash_media_encryption" {
  description = "Enable DASH media encryption. Only applies when enable_segmented_content_protection is true."
  type        = bool
  default     = false
}

variable "hls_media_encryption" {
  description = "Enable HLS media encryption. Only applies when enable_segmented_content_protection is true."
  type        = bool
  default     = false
}

variable "enable_debug" {
  description = "Enable the enhanced_debug behavior. Off by default; set to true in tfvars to enable."
  type        = bool
  default     = false
}

variable "debug_key" {
  description = "Optional enhanced-debug key. If omitted while debug is enabled, Terraform generates a stable key."
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.debug_key == null || can(regex("^[0-9a-fA-F]{64}$", var.debug_key))
    error_message = "debug_key must be exactly 64 hexadecimal characters."
  }
}

## ----------------------------------------------------------------------------
## Activation
## ----------------------------------------------------------------------------

variable "emails" {
  description = "Email addresses notified on activation."
  type        = list(string)

  validation {
    condition     = length(var.emails) > 0
    error_message = "At least one email should be provided."
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

variable "activation_to_staging_exists" {
  description = "Do not modify. Preserves the existing staging activation when activate_to_staging is false."
  type        = bool
  default     = false
}

variable "activation_to_production_exists" {
  description = "Do not modify. Preserves the existing production activation when activate_to_production is false."
  type        = bool
  default     = false
}

variable "noncompliance_reason" {
  description = "Compliance record marker for production activation. Allowed values: NONE, OTHER, NO_PRODUCTION_TRAFFIC, EMERGENCY."
  type        = list(string)
  default     = []
}

variable "ticket_id" {
  description = "Change/ticket ID for production activation."
  type        = string
  default     = null
}

variable "other_noncompliance_reason" {
  description = "Free-text explanation used when noncompliance_reason is [\"OTHER\"]."
  type        = string
  default     = null
}

variable "peer_reviewed_by" {
  description = "Peer reviewer identity used when noncompliance_reason is [\"NONE\"]."
  type        = string
  default     = null
}

variable "customer_email" {
  description = "Customer contact email used when noncompliance_reason is [\"NONE\"]."
  type        = string
  default     = null
}

variable "unit_tested" {
  description = "Whether the change has been unit tested. Used when noncompliance_reason is [\"NONE\"]."
  type        = bool
  default     = null
}

variable "activation_notes" {
  description = "Activation notes."
  type        = string
  default     = "Activated via Terraform"
}

## ----------------------------------------------------------------------------
## CP Code
## ----------------------------------------------------------------------------

variable "cpcode_name" {
  description = "CP code name. Will be the property name (var.name) if null."
  type        = string
  default     = null
}
