# ============================================================
# Provider / Authentication
# ============================================================

variable "edgerc_path" {
  description = "Path to the Akamai EdgeGrid authentication file (e.g. ~/.edgerc)."
  type        = string
  default     = "~/.edgerc"
}

variable "edgerc_section" {
  description = "Section inside the edgerc file containing API credentials."
  type        = string
  default     = "default"
}

variable "group_name" {
  description = "Akamai Group name under which resources will be managed."
  type        = string
}



# ============================================================
# Global Activation Controls
# ============================================================

variable "activate_to_staging" {
  description = "Set to true to activate resources to the STAGING network."
  type        = bool
  default     = false
}

variable "activate_to_production" {
  description = "Set to true to activate resources to the PRODUCTION network."
  type        = bool
  default     = false
}

variable "activation_to_staging_exists" {
  description = "Internal flag indicating whether a staging activation already exists."
  type        = bool
  default     = false
}

variable "activation_to_production_exists" {
  description = "Internal flag indicating whether a production activation already exists."
  type        = bool
  default     = false
}



# ============================================================
# API Definition Inputs
# ============================================================

variable "apis" {
  description = "Map of logical API keys to OpenAPI specification files."
  type        = map(string)
  default = {
    api1 = "null"
  }
}

variable "operations" {
  description = "Map of logical API keys to operations definition JSON files. Keys must match the 'apis' map."
  type        = map(string)
  default = {
    api1 = "null"
  }
}

variable "emails" {
  description = "List of email addresses to receive activation notifications."
  type        = list(string)
  default     = ["noreply@akamai.com"]
}


# ============================================================
# Security Configuration
# ============================================================

variable "config_name" {
  description = "Name of the existing AppSec security configuration."
  type        = string
}

variable "policy_name" {
  description = "Security policy name within the specified configuration."
  type        = string
}



# ============================================================
# Bot Manager – JavaScript Injection
# ============================================================

# tflint-ignore: terraform_unused_declarations 
variable "enable_js_injection" {
  description = "Mandatory flag or value to enable JavaScript injection logic. DO NOT Delete"
  type        = string
  default     = ""
}

variable "javascript_hostnames" {
  description = "List of hostnames where JavaScript injection rules will apply."
  type        = list(string)
}

variable "injection_type" {
  description = "JavaScript injection mode. Allowed values: NEVER, AROUND_PROTECTED_OPERATIONS, ALWAYS."
  type        = string
}



# ============================================================
# Telemetry Expectations
# ============================================================

variable "expect_inline_traffic" {
  description = "Indicates whether inline traffic is expected."
  type        = bool
}

variable "expect_sdk_traffic" {
  description = "Indicates whether SDK-based traffic is expected."
  type        = bool
}

variable "expect_standard_traffic" {
  description = "Indicates whether standard traffic is expected."
  type        = bool
}



# ============================================================
# Versioning / Activation Notes
# ============================================================

variable "version_notes" {
  description = "Version or activation notes applied during resource activation."
  type        = string
  default     = "Initial Config"
}