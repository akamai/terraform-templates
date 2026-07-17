<!-- BEGIN_TF_DOCS -->



# Usage
Basic usage of this module is as follows:

```hcl
module "example" {
  	 source  = "<module-location>"
  
	 # Required variables
  	 environment  = <string>
  	 group_name  = <string>
  
	 # Optional variables
  	 activate_to_production  = <bool> | default: false
  	 activate_to_staging  = <bool> | default: false
  	 activation_notes  = <string> | default: "Activated by Terraform"
  	 activation_to_production_exists  = <bool> | default: false
  	 activation_to_staging_exists  = <bool> | default: false
  	 akamai_access_token  = <string> | default: ""
  	 akamai_account_key  = <string> | default: ""
  	 akamai_client_secret  = <string> | default: ""
  	 akamai_client_token  = <string> | default: ""
  	 akamai_host  = <string> | default: ""
  	 edgerc_path  = <string> | default: "~/.edgerc"
  	 edgerc_section  = <string> | default: "default"
  	 emails  = <list(string)> | default: [
  "noreply@akamai.com"
]
  	 version_notes  = <string> | default: "Initial Config"
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_akamai"></a> [akamai](#requirement\_akamai) | ~> 9.0 |

## Resources

No resources.

## Modules

No modules.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Environment (e.g. dev, qa, prod) | `string` | n/a | yes |
| <a name="input_group_name"></a> [group\_name](#input\_group\_name) | Akamai Group Name | `string` | n/a | yes |
| <a name="input_activate_to_production"></a> [activate\_to\_production](#input\_activate\_to\_production) | Set to true to activate on the production network. | `bool` | `false` | no |
| <a name="input_activate_to_staging"></a> [activate\_to\_staging](#input\_activate\_to\_staging) | Set to true to activate on the staging network. | `bool` | `false` | no |
| <a name="input_activation_notes"></a> [activation\_notes](#input\_activation\_notes) | Notes for the activation | `string` | `"Activated by Terraform"` | no |
| <a name="input_activation_to_production_exists"></a> [activation\_to\_production\_exists](#input\_activation\_to\_production\_exists) | Do not modify. Flag used by deploy.ps1 for the initial production activation. | `bool` | `false` | no |
| <a name="input_activation_to_staging_exists"></a> [activation\_to\_staging\_exists](#input\_activation\_to\_staging\_exists) | Do not modify. Flag used by deploy.ps1 for the initial staging activation. | `bool` | `false` | no |
| <a name="input_akamai_access_token"></a> [akamai\_access\_token](#input\_akamai\_access\_token) | Akamai access\_token API credential | `string` | `""` | no |
| <a name="input_akamai_account_key"></a> [akamai\_account\_key](#input\_akamai\_account\_key) | Akamai Account Key | `string` | `""` | no |
| <a name="input_akamai_client_secret"></a> [akamai\_client\_secret](#input\_akamai\_client\_secret) | Akamai client\_secret API credential | `string` | `""` | no |
| <a name="input_akamai_client_token"></a> [akamai\_client\_token](#input\_akamai\_client\_token) | Akamai client\_token API credential | `string` | `""` | no |
| <a name="input_akamai_host"></a> [akamai\_host](#input\_akamai\_host) | Akamai host API credential | `string` | `""` | no |
| <a name="input_edgerc_path"></a> [edgerc\_path](#input\_edgerc\_path) | Specify path to the Akamai EdgeGrid authentication file that contains your Akamai API tokens. Typically ~/.edgerc. | `string` | `"~/.edgerc"` | no |
| <a name="input_edgerc_section"></a> [edgerc\_section](#input\_edgerc\_section) | Specify the section inside the edgerc file which can contain multiple sets of Akamai API tokens. Typically default. | `string` | `"default"` | no |
| <a name="input_emails"></a> [emails](#input\_emails) | List of email addresses for activation notifications | `list(string)` | <pre>[<br/>  "noreply@akamai.com"<br/>]</pre> | no |
| <a name="input_version_notes"></a> [version\_notes](#input\_version\_notes) | Configuration version notes | `string` | `"Initial Config"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->