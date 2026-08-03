<!-- BEGIN_TF_DOCS -->

# Onboarding: Akamai DataStream 2 (DS-managed / Decoupled)

This template provisions a **DataStream 2 (DS2)** configuration using the
decoupled ("DS-managed") workflow. It collects delivery logs for existing
Akamai properties **without** requiring any DataStream behavior in the
Property Manager rule tree.

Existing properties are associated via `property_ids` — the stream runs in
`DS_MANAGED` mode and begins delivering logs when those properties are active.

## Authentication

Please refer to [Terraform Overview](https://techdocs.akamai.com/terraform/docs/overview)
and [Terraform Alternative authentication](https://techdocs.akamai.com/terraform/docs/gs-authentication)
for details on how to authenticate to Akamai when using Terraform.

Authentication is provided via a `.edgerc` file and the `edgerc_section`
variable.

## Usage Instructions

### Step 1: Download the Templates
Clone the repository, using the following command:

```bash
> git clone <git url>
> cd terraform-templates/new-ds2/
```

### Step 2: Update the environment `.tfvars`
Copy the `.tfvars.dist` file for your environment (for example
`environments/dev/dev.tfvars.dist`), remove the `.dist` extension, and fill in:

- `edgerc_section` — account section in your `.edgerc` file
- `contract_id` / `group_id` — target contract and group
- `name` — the DataStream name
- `property_ids` — the Akamai property IDs to monitor
- Exactly **one** connector block (S3, Datadog, Splunk, HTTPS, etc.)

### Step 3: Run Terraform
Run the deployment script `../deploy.ps1`. This script acts as an orchestrator
for Terraform, handling multi-environment state isolation and save/activate
actions.

## Connectors

Exactly **one** connector must be configured. Supported destinations:

- AWS S3 (`s3_connector`)
- S3-Compatible — MinIO, Wasabi, Cloudflare R2 (`s3_compatible_connector`)
- Azure Blob Storage (`azure_connector`)
- Google Cloud Storage (`gcs_connector`)
- Oracle Cloud Object Storage (`oracle_connector`)
- Datadog (`datadog_connector`)
- Splunk (`splunk_connector`)
- Custom HTTPS (`https_connector`)
- Sumo Logic (`sumologic_connector`)
- Loggly (`loggly_connector`)
- New Relic (`new_relic_connector`)
- Elasticsearch (`elasticsearch_connector`)
- Dynatrace (`dynatrace_connector`)
- TrafficPeak / Hydrolix (`trafficpeak_connector`)

# Usage
Basic usage of this module is as follows:

```hcl
module "example" {
  	 source  = "<module-location>"
  
	 # Required variables
  	 contract_id  = <string>
  	 edgerc_section  = <string>
  	 group_id  = <string>
  	 name  = <string>
  	 property_ids  = <list(string)>
  
	 # Optional variables
  	 activate_stream  = <bool> | default: true
  	 azure_connector  = <object({
	    display_name   = string
	    account_name   = string
	    container_name = string
	    access_key     = string
	    path           = string
	  })> | default: null
  	 datadog_connector  = <object({
	    display_name  = string
	    endpoint      = string
	    auth_token    = string
	    service       = optional(string)
	    source        = optional(string)
	    tags          = optional(string)
	    compress_logs = optional(bool)
	  })> | default: null
  	 dataset_fields_ids  = <list(number)> | default: [
  1000,
  1002,
  1015,
  1037,
  1100
]
  	 dynatrace_connector  = <object({
	    display_name        = string
	    endpoint            = string
	    api_token           = string
	    custom_header_name  = optional(string)
	    custom_header_value = optional(string)
	  })> | default: null
  	 edgerc_path  = <string> | default: "~/.edgerc"
  	 elasticsearch_connector  = <object({
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
	  })> | default: null
  	 enable_midgress  = <bool> | default: false
  	 field_delimiter  = <string> | default: null
  	 gcs_connector  = <object({
	    display_name         = string
	    bucket               = string
	    private_key          = string
	    project_id           = string
	    service_account_name = string
	    path                 = optional(string)
	  })> | default: null
  	 https_connector  = <object({
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
	  })> | default: null
  	 interval_in_secs  = <number> | default: 60
  	 log_format  = <string> | default: "JSON"
  	 loggly_connector  = <object({
	    display_name        = string
	    endpoint            = string
	    auth_token          = string
	    tags                = optional(string)
	    content_type        = optional(string)
	    custom_header_name  = optional(string)
	    custom_header_value = optional(string)
	  })> | default: null
  	 new_relic_connector  = <object({
	    display_name        = string
	    endpoint            = string
	    auth_token          = string
	    content_type        = optional(string)
	    custom_header_name  = optional(string)
	    custom_header_value = optional(string)
	  })> | default: null
  	 notification_emails  = <list(string)> | default: []
  	 oracle_connector  = <object({
	    display_name      = string
	    bucket            = string
	    region            = string
	    namespace         = string
	    path              = string
	    access_key        = string
	    secret_access_key = string
	  })> | default: null
  	 s3_compatible_connector  = <object({
	    display_name      = string
	    endpoint          = string
	    bucket            = string
	    region            = string
	    access_key        = string
	    secret_access_key = string
	    path              = optional(string)
	  })> | default: null
  	 s3_connector  = <object({
	    display_name      = string
	    bucket            = string
	    region            = string
	    access_key        = string
	    secret_access_key = string
	    path              = string
	  })> | default: null
  	 sampling_percentage  = <number> | default: null
  	 splunk_connector  = <object({
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
	  })> | default: null
  	 sumologic_connector  = <object({
	    display_name        = string
	    endpoint            = string
	    collector_code      = string
	    content_type        = optional(string)
	    compress_logs       = optional(bool)
	    custom_header_name  = optional(string)
	    custom_header_value = optional(string)
	  })> | default: null
  	 trafficpeak_connector  = <object({
	    display_name        = string
	    endpoint            = string
	    authentication_type = string
	    content_type        = string
	    user_name           = string
	    password            = string
	    custom_header_name  = optional(string)
	    custom_header_value = optional(string)
	    compress_logs       = optional(bool)
	  })> | default: null
  	 upload_file_prefix  = <string> | default: null
  	 upload_file_suffix  = <string> | default: null
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_akamai"></a> [akamai](#requirement\_akamai) | ~> 10.1 |

## Resources

No resources.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ds2"></a> [ds2](#module\_ds2) | git::https://github.com/akamai/terraform-templates-modules.git//ds2 | v1.5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_contract_id"></a> [contract\_id](#input\_contract\_id) | Contract ID for property/config creation. | `string` | n/a | yes |
| <a name="input_edgerc_section"></a> [edgerc\_section](#input\_edgerc\_section) | Section in the .edgerc file.<br/><br/>    For professional services, it is recommended to create a new section for<br/>    each account managed. | `string` | n/a | yes |
| <a name="input_group_id"></a> [group\_id](#input\_group\_id) | Group ID for property/config creation. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the DataStream 2 configuration and CP Code. | `string` | n/a | yes |
| <a name="input_property_ids"></a> [property\_ids](#input\_property\_ids) | List of Akamai Property IDs to monitor (Decoupled architecture). | `list(string)` | n/a | yes |
| <a name="input_activate_stream"></a> [activate\_stream](#input\_activate\_stream) | Whether to activate the stream upon creation. | `bool` | `true` | no |
| <a name="input_azure_connector"></a> [azure\_connector](#input\_azure\_connector) | Configuration for Azure Storage destination. | <pre>object({<br/>    display_name   = string<br/>    account_name   = string<br/>    container_name = string<br/>    access_key     = string<br/>    path           = string<br/>  })</pre> | `null` | no |
| <a name="input_datadog_connector"></a> [datadog\_connector](#input\_datadog\_connector) | Configuration for Datadog destination.<br/><br/>    NOTE: Akamai DataStream only supports Datadog v1 endpoints, not v2.<br/>    Akamai validates the API key with a live POST before creating the stream.<br/>    Correct endpoint format (include https:// scheme):<br/>      EU: https://http-intake.logs.datadoghq.eu/v1/input<br/>      US: https://http-intake.logs.datadoghq.com/v1/input | <pre>object({<br/>    display_name  = string<br/>    endpoint      = string<br/>    auth_token    = string<br/>    service       = optional(string)<br/>    source        = optional(string)<br/>    tags          = optional(string)<br/>    compress_logs = optional(bool)<br/>  })</pre> | `null` | no |
| <a name="input_dataset_fields_ids"></a> [dataset\_fields\_ids](#input\_dataset\_fields\_ids) | List of dataset fields IDs to log. | `list(number)` | <pre>[<br/>  1000,<br/>  1002,<br/>  1015,<br/>  1037,<br/>  1100<br/>]</pre> | no |
| <a name="input_dynatrace_connector"></a> [dynatrace\_connector](#input\_dynatrace\_connector) | Configuration for Dynatrace destination. Endpoint must be in https://{environment-id}.live.dynatrace.com/api/v2/logs/ingest format. | <pre>object({<br/>    display_name        = string<br/>    endpoint            = string<br/>    api_token           = string<br/>    custom_header_name  = optional(string)<br/>    custom_header_value = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_edgerc_path"></a> [edgerc\_path](#input\_edgerc\_path) | Path to the .edgerc file. | `string` | `"~/.edgerc"` | no |
| <a name="input_elasticsearch_connector"></a> [elasticsearch\_connector](#input\_elasticsearch\_connector) | Configuration for Elasticsearch destination. Akamai uses BASIC auth (user\_name + password) to authenticate. | <pre>object({<br/>    display_name        = string<br/>    endpoint            = string<br/>    user_name           = string<br/>    password            = string<br/>    index_name          = string<br/>    content_type        = optional(string)<br/>    custom_header_name  = optional(string)<br/>    custom_header_value = optional(string)<br/>    tls_hostname        = optional(string)<br/>    ca_cert             = optional(string)<br/>    client_cert         = optional(string)<br/>    client_key          = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_enable_midgress"></a> [enable\_midgress](#input\_enable\_midgress) | Enable midgress traffic collection (sets collect\_midgress on the stream). Requires dataset field 2084 to log midgress hits. | `bool` | `false` | no |
| <a name="input_field_delimiter"></a> [field\_delimiter](#input\_field\_delimiter) | Delimiter between log fields. Must be SPACE. Only valid when log\_format is STRUCTURED. | `string` | `null` | no |
| <a name="input_gcs_connector"></a> [gcs\_connector](#input\_gcs\_connector) | Configuration for Google Cloud Storage destination. | <pre>object({<br/>    display_name         = string<br/>    bucket               = string<br/>    private_key          = string<br/>    project_id           = string<br/>    service_account_name = string<br/>    path                 = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_https_connector"></a> [https\_connector](#input\_https\_connector) | Configuration for a custom HTTPS destination. authentication\_type must be NONE or BASIC. | <pre>object({<br/>    display_name        = string<br/>    endpoint            = string<br/>    authentication_type = string<br/>    content_type        = optional(string)<br/>    custom_header_name  = optional(string)<br/>    custom_header_value = optional(string)<br/>    user_name           = optional(string)<br/>    password            = optional(string)<br/>    compress_logs       = optional(bool)<br/>    tls_hostname        = optional(string)<br/>    ca_cert             = optional(string)<br/>    client_cert         = optional(string)<br/>    client_key          = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_interval_in_secs"></a> [interval\_in\_secs](#input\_interval\_in\_secs) | Seconds after which log lines are bundled and sent to the destination. Must be 30 or 60. | `number` | `60` | no |
| <a name="input_log_format"></a> [log\_format](#input\_log\_format) | Format of the logs. Must be JSON or STRUCTURED. When STRUCTURED, a field\_delimiter is used. | `string` | `"JSON"` | no |
| <a name="input_loggly_connector"></a> [loggly\_connector](#input\_loggly\_connector) | Configuration for Loggly destination. Akamai appends auth\_token to the endpoint URL to form the full bulk ingest URL. | <pre>object({<br/>    display_name        = string<br/>    endpoint            = string<br/>    auth_token          = string<br/>    tags                = optional(string)<br/>    content_type        = optional(string)<br/>    custom_header_name  = optional(string)<br/>    custom_header_value = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_new_relic_connector"></a> [new\_relic\_connector](#input\_new\_relic\_connector) | Configuration for New Relic destination. auth\_token is sent as the Api-Key header. | <pre>object({<br/>    display_name        = string<br/>    endpoint            = string<br/>    auth_token          = string<br/>    content_type        = optional(string)<br/>    custom_header_name  = optional(string)<br/>    custom_header_value = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_notification_emails"></a> [notification\_emails](#input\_notification\_emails) | Email addresses to notify on stream activation or deactivation status changes. | `list(string)` | `[]` | no |
| <a name="input_oracle_connector"></a> [oracle\_connector](#input\_oracle\_connector) | Configuration for Oracle Cloud Storage destination. | <pre>object({<br/>    display_name      = string<br/>    bucket            = string<br/>    region            = string<br/>    namespace         = string<br/>    path              = string<br/>    access_key        = string<br/>    secret_access_key = string<br/>  })</pre> | `null` | no |
| <a name="input_s3_compatible_connector"></a> [s3\_compatible\_connector](#input\_s3\_compatible\_connector) | Configuration for S3-compatible destinations (MinIO, Wasabi, Cloudflare R2, etc.). | <pre>object({<br/>    display_name      = string<br/>    endpoint          = string<br/>    bucket            = string<br/>    region            = string<br/>    access_key        = string<br/>    secret_access_key = string<br/>    path              = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_s3_connector"></a> [s3\_connector](#input\_s3\_connector) | Configuration for AWS S3 destination. | <pre>object({<br/>    display_name      = string<br/>    bucket            = string<br/>    region            = string<br/>    access_key        = string<br/>    secret_access_key = string<br/>    path              = string<br/>  })</pre> | `null` | no |
| <a name="input_sampling_percentage"></a> [sampling\_percentage](#input\_sampling\_percentage) | Percentage (1-100) of log data to collect and deliver. Defaults to 100 when null. | `number` | `null` | no |
| <a name="input_splunk_connector"></a> [splunk\_connector](#input\_splunk\_connector) | Configuration for Splunk destination. NOTE: Akamai DataStream only accepts the Splunk HEC raw endpoint — the URL must end with /services/collector/raw. | <pre>object({<br/>    display_name          = string<br/>    endpoint              = string<br/>    event_collector_token = string<br/>    compress_logs         = optional(bool)<br/>    custom_header_name    = optional(string)<br/>    custom_header_value   = optional(string)<br/>    tls_hostname          = optional(string)<br/>    ca_cert               = optional(string)<br/>    client_cert           = optional(string)<br/>    client_key            = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_sumologic_connector"></a> [sumologic\_connector](#input\_sumologic\_connector) | Configuration for Sumo Logic destination. Akamai appends collector\_code to the endpoint URL. | <pre>object({<br/>    display_name        = string<br/>    endpoint            = string<br/>    collector_code      = string<br/>    content_type        = optional(string)<br/>    compress_logs       = optional(bool)<br/>    custom_header_name  = optional(string)<br/>    custom_header_value = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_trafficpeak_connector"></a> [trafficpeak\_connector](#input\_trafficpeak\_connector) | Configuration for TrafficPeak (Hydrolix) destination. authentication\_type must be BASIC. Endpoint must include table and token query params. | <pre>object({<br/>    display_name        = string<br/>    endpoint            = string<br/>    authentication_type = string<br/>    content_type        = string<br/>    user_name           = string<br/>    password            = string<br/>    custom_header_name  = optional(string)<br/>    custom_header_value = optional(string)<br/>    compress_logs       = optional(bool)<br/>  })</pre> | `null` | no |
| <a name="input_upload_file_prefix"></a> [upload\_file\_prefix](#input\_upload\_file\_prefix) | Log file name prefix sent to the destination. Defaults to 'ak' when null. | `string` | `null` | no |
| <a name="input_upload_file_suffix"></a> [upload\_file\_suffix](#input\_upload\_file\_suffix) | Log file name suffix sent to the destination. Defaults to 'ds' when null. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_stream_id"></a> [stream\_id](#output\_stream\_id) | The ID of the created DataStream. |
| <a name="output_stream_name"></a> [stream\_name](#output\_stream\_name) | The name of the created DataStream. |
<!-- END_TF_DOCS -->