variable "edgerc_path" {
  type    = string
  default = "~/.edgerc"
}

variable "edgerc_section" {
  description = <<EOD
    Section in the .edgerc file.

    For professional services, it is recommended to create a new section for
    each account managed.
  EOD
  type        = string
}

variable "common_name" {
  description = "Primary common name for the certificate."
  type        = string
}

variable "allow_duplicate_common_name" {
  description = "Whether to allow duplicate common names."
  type        = bool
  default     = false
}

variable "sans" {
  description = "List of Subject Alternative Names (SANs)."
  type        = list(string)
  default     = []
}

variable "secure_network" {
  description = "Secure network type. Valid values: enhanced-tls, standard-tls."
  type        = string
  default     = "enhanced-tls"
}

variable "sni_only" {
  description = "Whether to enable SNI-only."
  type        = bool
  default     = true
}

variable "acknowledge_pre_verification_warnings" {
  description = "Acknowledge warnings before verification."
  type        = bool
  default     = true
}

variable "admin_contact" {
  description = "Admin contact details."
  type = object({
    first_name       = string
    last_name        = string
    organization     = string
    email            = string
    phone            = string
    address_line_one = string
    city             = string
    region           = string
    postal_code      = string
    country_code     = string
  })
}

variable "certificate_chain_type" {
  description = "Certificate chain type (default or test)."
  type        = string
  default     = "default"
}

variable "csr" {
  description = "Certificate Signing Request details."
  type = object({
    country_code        = string
    city                = string
    organization        = string
    organizational_unit = string
    state               = string
  })
}

variable "network_configuration" {
  description = "TLS and network configuration settings."
  type = object({
    disallowed_tls_versions = list(string)
    clone_dns_names         = bool
    geography               = string
    must_have_ciphers       = string
    ocsp_stapling           = string
    preferred_ciphers       = string
  })
}

variable "signature_algorithm" {
  description = "Signature algorithm (e.g., SHA-256)."
  type        = string
  default     = "SHA-256"
}

variable "tech_contact" {
  description = "Technical contact details."
  type = object({
    first_name       = string
    last_name        = string
    organization     = string
    email            = string
    phone            = string
    address_line_one = string
    city             = string
    region           = string
    postal_code      = string
    country_code     = string
  })
}

variable "organization" {
  description = "Organization details for the enrollment."
  type = object({
    name             = string
    phone            = string
    address_line_one = string
    address_line_two = string
    city             = string
    region           = string
    postal_code      = string
    country_code     = string
  })
}

variable "contract_id" {
  description = "Akamai contract ID."
  type        = string
}

variable "cert_name" {
  description = "Certificate name / identifier (e.g. cert1)"
  type        = string
}