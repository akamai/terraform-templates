## ----------------------------------------------------------------------------
## EdgeGrid
## ----------------------------------------------------------------------------

variable "edgerc_path" {
  description = <<EOD
    Path to the .edgerc file.
  EOD
  type        = string
  default     = null
}

variable "edgerc_section" {
  description = <<EOD
    Section in the .edgerc file.

    For professional services, it is recommended to create a new section for
    each account managed.
  EOD
  type        = string
  default     = null
}

## ----------------------------------------------------------------------------
## Scope
## ----------------------------------------------------------------------------

variable "zone_name" {
  description = "DNS zone name (e.g. example.com)"
  type        = string
}

variable "zone_type" {
  description = "Zone type: PRIMARY or SECONDARY"
  type        = string

  validation {
    condition     = contains(["primary", "secondary"], lower(var.zone_type))
    error_message = "zone_type must be PRIMARY or SECONDARY (case-insensitive)."
  }
}

variable "contract_id" {
  description = "Akamai contract ID"
  type        = string
}

variable "group_id" {
  description = "Akamai group ID"
  type        = string
}

## ----------------------------------------------------------------------------
# SECONDARY only
## ----------------------------------------------------------------------------

variable "masters" {
  description = "Master DNS server IPs for SECONDARY zone"
  type        = list(string)
  default     = []
}

variable "tsig_key" {
  description = "Optional TSIG key for zone transfers (SECONDARY only)"
  type = object({
    name      = string
    algorithm = string
    secret    = string
  })
  default = null
}

## ----------------------------------------------------------------------------
# Optional SOA (PRIMARY only)
## ----------------------------------------------------------------------------

variable "soa" {
  description = "SOA record configuration (null = unmanaged)"
  type = object({
    email        = string
    name_server  = string
    ttl          = number
    refresh      = number
    retry        = number
    expiry       = number
    nxdomain_ttl = number
  })
  default  = null
  nullable = true
}

## ----------------------------------------------------------------------------
# BASIC RECORDS
## ----------------------------------------------------------------------------

variable "a_records" {
  type = list(object({
    name   = string
    target = list(string)
    ttl    = number
  }))
  default = []
}

variable "aaaa_records" {
  type = list(object({
    name   = string
    target = list(string)
    ttl    = number
  }))
  default = []
}

variable "cname_records" {
  type = list(object({
    name   = string
    target = list(string)
    ttl    = number
  }))
  default = []
}

variable "txt_records" {
  type = list(object({
    name   = string
    target = list(string)
    ttl    = number
  }))
  default = []
}

variable "ns_records" {
  type = list(object({
    name   = string
    target = list(string)
    ttl    = number
  }))
  default = []
}

variable "ptr_records" {
  type = list(object({
    name   = string
    target = list(string)
    ttl    = number
  }))
  default = []
}

variable "loc_records" {
  type = list(object({
    name   = string
    target = list(string)
    ttl    = number
  }))
  default = []
}

variable "spf_records" {
  type = list(object({
    name   = string
    target = list(string)
    ttl    = number
  }))
  default = []
}

variable "rp_records" {
  type = list(object({
    name    = string
    mailbox = string
    txt     = string
    ttl     = number
  }))
  default = []
}

variable "hinfo_records" {
  type = list(object({
    name     = string
    hardware = string
    software = string
    ttl      = number
  }))
  default = []
}

## ----------------------------------------------------------------------------
# ADVANCED RECORDS
## ----------------------------------------------------------------------------

variable "mx_records" {
  type = list(object({
    name               = string
    target             = list(string)
    ttl                = number
    priority           = optional(number)
    priority_increment = optional(number)
  }))
  default = []
}

variable "srv_records" {
  type = list(object({
    name     = string
    target   = list(string)
    ttl      = number
    priority = number
    weight   = number
    port     = number
  }))
  default = []
}

variable "caa_records" {
  type = list(object({
    name   = string
    target = list(string)
    ttl    = number
  }))
  default = []
}

## ----------------------------------------------------------------------------
# Fix to remove records while destroy
## ----------------------------------------------------------------------------
variable "force_empty_records" {
  description = "Force all DNS record lists to be empty (used for safe destroy)"
  type        = bool
  default     = false
}
variable "destroy_mode" {
  type    = bool
  default = false
}