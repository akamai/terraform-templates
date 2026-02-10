# ------------------------
# Enrollment Variables
# ------------------------
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
  description = "Primary certificate common name"
  type        = string
}

variable "allow_duplicate_common_name" {
  description = "Whether duplicate common names are allowed"
  type        = bool
  default     = false
}

variable "sans" {
  description = "Subject Alternative Names for the certificate"
  type        = list(string)
}

variable "secure_network" {
  description = "TLS network setting"
  type        = string
  default     = "standard-tls"
}

variable "sni_only" {
  description = "Enable SNI-only certificates"
  type        = bool
  default     = true
}

variable "acknowledge_pre_verification_warnings" {
  description = "Acknowledge pre-verification warnings"
  type        = bool
  default     = false
}

variable "auto_approve_warnings" {
  description = "List of warnings to auto-approve"
  type        = list(string)
  default     = []
}

# ------------------------
# Admin Contact
# ------------------------

variable "admin_contact" {
  description = "Admin contact details"
  type = object({
    first_name       = string
    last_name        = string
    organization     = string
    email            = string
    phone            = string
    address_line_one = string
    address_line_two = string
    city             = string
    region           = string
    postal_code      = string
    country_code     = string
  })
}

# ------------------------
# CSR
# ------------------------

variable "csr" {
  description = "CSR details"
  type = object({
    country_code        = string
    city                = string
    organization        = string
    organizational_unit = string
    state               = string
  })
}

# ------------------------
# Network Configuration
# ------------------------

variable "network_configuration" {
  description = "Network configuration for enrollment"
  type = object({
    disallowed_tls_versions = list(string)
    clone_dns_names         = bool
    geography               = string
    must_have_ciphers       = string
    ocsp_stapling           = string
    preferred_ciphers       = string
    quic_enabled            = bool
  })
}

# ------------------------
# Other Enrollment Settings
# ------------------------

variable "signature_algorithm" {
  description = "Signature algorithm for CSR"
  type        = string
  default     = ""
}

# ------------------------
# Tech Contact
# ------------------------

variable "tech_contact" {
  description = "Technical contact details"
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

# ------------------------
# Organization
# ------------------------

variable "organization" {
  description = "Organization details"
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
  description = "Akamai contract ID"
  type        = string
}

variable "change_management" {
  description = "Enable/disable change management"
  type        = bool
  default     = false
}

# ------------------------
# Upload Certificate Variables
# ------------------------

variable "certificate_ecdsa_pem" {
  description = "ECDSA certificate PEM string"
  type        = string
}

variable "certificate_rsa_pem" {
  description = "RSA certificate PEM string"
  type        = string
}

variable "trust_chain_ecdsa_pem" {
  description = "ECDSA trust chain PEM string"
  type        = string
}

variable "trust_chain_rsa_pem" {
  description = "RSA trust chain PEM string"
  type        = string
}

variable "acknowledge_post_verification_warnings" {
  description = "Acknowledge post-verification warnings"
  type        = bool
  default     = false
}

variable "acknowledge_change_management" {
  description = "Acknowledge change management for certificate upload"
  type        = bool
  default     = false
}

variable "wait_for_deployment" {
  description = "Wait for deployment to complete before proceeding"
  type        = bool
  default     = false
}

# tflint-ignore: terraform_unused_declarations
variable "enrollment_id" {
  description = "Enrollment ID for the uploaded certificate"
  type        = number
}

variable "cert_name" {
  description = "Certificate name / identifier (e.g. cert1)"
  type        = string
}