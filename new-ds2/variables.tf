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

variable "name" {
  type        = string
  description = "Name of the DataStream 2 configuration and CP Code."
}

variable "group_id" {
  type        = string
  description = "Group ID for property/config creation."
}

variable "contract_id" {
  type        = string
  description = "Contract ID for property/config creation."
}

variable "property_ids" {
  type        = list(string)
  description = "List of Akamai Property IDs to monitor (Decoupled architecture)."
}

## ----------------------------------------------------------------------------
## Stream behaviour
## ----------------------------------------------------------------------------

variable "activate_stream" {
  type        = bool
  description = "Whether to activate the stream upon creation."
  default     = true
}

variable "notification_emails" {
  type        = list(string)
  description = "Email addresses to notify on stream activation or deactivation status changes."
  default     = []
}

variable "enable_midgress" {
  type        = bool
  description = "Enable midgress traffic collection (sets collect_midgress on the stream). Requires dataset field 2084 to log midgress hits."
  default     = false
}

variable "dataset_fields_ids" {
  type        = list(number)
  description = "List of dataset fields IDs to log."
  default     = [1000, 1002, 1015, 1037, 1100]
}

variable "sampling_percentage" {
  type        = number
  description = "Percentage (1-100) of log data to collect and deliver. Defaults to 100 when null."
  default     = null
  validation {
    condition     = var.sampling_percentage == null || (var.sampling_percentage >= 1 && var.sampling_percentage <= 100)
    error_message = "sampling_percentage must be between 1 and 100."
  }
}

variable "log_format" {
  type        = string
  description = "Format of the logs. Must be JSON or STRUCTURED. When STRUCTURED, a field_delimiter is used."
  default     = "JSON"
  validation {
    condition     = contains(["JSON", "STRUCTURED"], var.log_format)
    error_message = "log_format must be either JSON or STRUCTURED."
  }
}

variable "field_delimiter" {
  type        = string
  description = "Delimiter between log fields. Must be SPACE. Only valid when log_format is STRUCTURED."
  default     = null
  validation {
    condition     = var.field_delimiter == null || var.field_delimiter == "SPACE"
    error_message = "field_delimiter must be SPACE or null."
  }
}

variable "interval_in_secs" {
  type        = number
  description = "Seconds after which log lines are bundled and sent to the destination. Must be 30 or 60."
  default     = 60
  validation {
    condition     = contains([30, 60], var.interval_in_secs)
    error_message = "interval_in_secs must be 30 or 60."
  }
}

variable "upload_file_prefix" {
  type        = string
  description = "Log file name prefix sent to the destination. Defaults to 'ak' when null."
  default     = null
}

variable "upload_file_suffix" {
  type        = string
  description = "Log file name suffix sent to the destination. Defaults to 'ds' when null."
  default     = null
}

## ----------------------------------------------------------------------------
## Connectors (configure exactly one)
## ----------------------------------------------------------------------------

variable "s3_connector" {
  description = "Configuration for AWS S3 destination."
  sensitive   = true
  type = object({
    display_name      = string
    bucket            = string
    region            = string
    access_key        = string
    secret_access_key = string
    path              = string
  })
  default = null
}

variable "datadog_connector" {
  description = <<EOD
    Configuration for Datadog destination.

    NOTE: Akamai DataStream only supports Datadog v1 endpoints, not v2.
    Akamai validates the API key with a live POST before creating the stream.
    Correct endpoint format (include https:// scheme):
      EU: https://http-intake.logs.datadoghq.eu/v1/input
      US: https://http-intake.logs.datadoghq.com/v1/input
  EOD
  sensitive   = true
  type = object({
    display_name  = string
    endpoint      = string
    auth_token    = string
    service       = optional(string)
    source        = optional(string)
    tags          = optional(string)
    compress_logs = optional(bool)
  })
  default = null
}

variable "splunk_connector" {
  description = "Configuration for Splunk destination. NOTE: Akamai DataStream only accepts the Splunk HEC raw endpoint — the URL must end with /services/collector/raw."
  sensitive   = true
  type = object({
    display_name          = string
    endpoint              = string
    event_collector_token = string
    compress_logs         = optional(bool)
    custom_header_name    = optional(string)
    custom_header_value   = optional(string)
    tls_hostname          = optional(string)
    ca_cert               = optional(string)
    client_cert           = optional(string)
    client_key            = optional(string)
  })
  default = null
}

variable "azure_connector" {
  description = "Configuration for Azure Storage destination."
  sensitive   = true
  type = object({
    display_name   = string
    account_name   = string
    container_name = string
    access_key     = string
    path           = string
  })
  default = null
}

variable "https_connector" {
  description = "Configuration for a custom HTTPS destination. authentication_type must be NONE or BASIC."
  sensitive   = true
  type = object({
    display_name        = string
    endpoint            = string
    authentication_type = string
    content_type        = optional(string)
    custom_header_name  = optional(string)
    custom_header_value = optional(string)
    user_name           = optional(string)
    password            = optional(string)
    compress_logs       = optional(bool)
    tls_hostname        = optional(string)
    ca_cert             = optional(string)
    client_cert         = optional(string)
    client_key          = optional(string)
  })
  default = null
  validation {
    condition     = var.https_connector == null || contains(["NONE", "BASIC"], var.https_connector.authentication_type)
    error_message = "https_connector.authentication_type must be NONE or BASIC."
  }
}

variable "elasticsearch_connector" {
  description = "Configuration for Elasticsearch destination. Akamai uses BASIC auth (user_name + password) to authenticate."
  sensitive   = true
  type = object({
    display_name        = string
    endpoint            = string
    user_name           = string
    password            = string
    index_name          = string
    content_type        = optional(string)
    custom_header_name  = optional(string)
    custom_header_value = optional(string)
    tls_hostname        = optional(string)
    ca_cert             = optional(string)
    client_cert         = optional(string)
    client_key          = optional(string)
  })
  default = null
}

variable "loggly_connector" {
  description = "Configuration for Loggly destination. Akamai appends auth_token to the endpoint URL to form the full bulk ingest URL."
  sensitive   = true
  type = object({
    display_name        = string
    endpoint            = string
    auth_token          = string
    tags                = optional(string)
    content_type        = optional(string)
    custom_header_name  = optional(string)
    custom_header_value = optional(string)
  })
  default = null
}

variable "new_relic_connector" {
  description = "Configuration for New Relic destination. auth_token is sent as the Api-Key header."
  sensitive   = true
  type = object({
    display_name        = string
    endpoint            = string
    auth_token          = string
    content_type        = optional(string)
    custom_header_name  = optional(string)
    custom_header_value = optional(string)
  })
  default = null
}

variable "s3_compatible_connector" {
  description = "Configuration for S3-compatible destinations (MinIO, Wasabi, Cloudflare R2, etc.)."
  sensitive   = true
  type = object({
    display_name      = string
    endpoint          = string
    bucket            = string
    region            = string
    access_key        = string
    secret_access_key = string
    path              = optional(string)
  })
  default = null
}

variable "sumologic_connector" {
  description = "Configuration for Sumo Logic destination. Akamai appends collector_code to the endpoint URL."
  sensitive   = true
  type = object({
    display_name        = string
    endpoint            = string
    collector_code      = string
    content_type        = optional(string)
    compress_logs       = optional(bool)
    custom_header_name  = optional(string)
    custom_header_value = optional(string)
  })
  default = null
}

variable "trafficpeak_connector" {
  description = "Configuration for TrafficPeak (Hydrolix) destination. authentication_type must be BASIC. Endpoint must include table and token query params."
  sensitive   = true
  type = object({
    display_name        = string
    endpoint            = string
    authentication_type = string
    content_type        = string
    user_name           = string
    password            = string
    custom_header_name  = optional(string)
    custom_header_value = optional(string)
    compress_logs       = optional(bool)
  })
  default = null
  validation {
    condition     = var.trafficpeak_connector == null || var.trafficpeak_connector.authentication_type == "BASIC"
    error_message = "trafficpeak_connector.authentication_type must be BASIC."
  }
}

variable "dynatrace_connector" {
  description = "Configuration for Dynatrace destination. Endpoint must be in https://{environment-id}.live.dynatrace.com/api/v2/logs/ingest format."
  sensitive   = true
  type = object({
    display_name        = string
    endpoint            = string
    api_token           = string
    custom_header_name  = optional(string)
    custom_header_value = optional(string)
  })
  default = null
}

variable "gcs_connector" {
  description = "Configuration for Google Cloud Storage destination."
  sensitive   = true
  type = object({
    display_name         = string
    bucket               = string
    private_key          = string
    project_id           = string
    service_account_name = string
    path                 = optional(string)
  })
  default = null
}

variable "oracle_connector" {
  description = "Configuration for Oracle Cloud Storage destination."
  sensitive   = true
  type = object({
    display_name      = string
    bucket            = string
    region            = string
    namespace         = string
    path              = string
    access_key        = string
    secret_access_key = string
  })
  default = null
}
