# -------------------------------------------------
# Environment variables (TF_VAR_*)
# These allow credentials to be passed via environment variables instead of .edgerc.
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

variable "environment" {
  description = "Environment (e.g. dev, qa, prod)"
  type        = string
}

variable "group_name" {
  description = "Akamai Group Name"
  type        = string
}

variable "emails" {
  description = "List of email addresses for activation notifications"
  type        = list(string)
  default     = ["noreply@akamai.com"]
}

variable "version_notes" {
  description = "Configuration version notes"
  type        = string
  default     = "Initial Config"
}

variable "activation_notes" {
  description = "Notes for the activation"
  type        = string
  default     = "Activated by Terraform"
}

variable "activate_to_staging" {
  description = "Set to true to activate on the staging network."
  type        = bool
  default     = false
}

variable "activate_to_production" {
  description = "Set to true to activate on the production network."
  type        = bool
  default     = false
}

variable "activation_to_staging_exists" {
  description = "Do not modify. Flag used by deploy.ps1 for the initial staging activation."
  type        = bool
  default     = false
}

variable "activation_to_production_exists" {
  description = "Do not modify. Flag used by deploy.ps1 for the initial production activation."
  type        = bool
  default     = false
}

# -------------------------------------------------
# TODO: Add product-specific variables below.
# -------------------------------------------------
