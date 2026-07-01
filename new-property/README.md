<!-- BEGIN_TF_DOCS -->

# Onboarding: Akamai Property

## Authentication

Please refer to [Terraform Overview](https://techdocs.akamai.com/terraform/docs/overview) and [Terraform Alternative authentication](https://techdocs.akamai.com/terraform/docs/gs-authentication) for more details on how to authenticate to Akamai when using Terraform.

## Usage Instructions
 Akamai Terraform Deployment Guide
 This guide will help you onboard hostnames using Akamai Terraform templates for:
     DSA, IOn and ION Premier: new-property

 ### Step 1: Download the Templates
 Clone the repository, using following command:

 ```bash
 > git clone <git url>
 > cd terraform-templates/new-property/
 ```

 ### Step 2: Update `terraform.tfvars`
 Update the `terraform.tfvars` file with the required details:

 #### Account Section as mentioned in the .edgerc file
 `edgerc_section = "<Account Section Name>"`

 Powershell command : `Get-AccountSwitchKey 'Account Name'`

 #### Name of the Configuration
 `name           = "<Config Name>"`

 #### Contract and Group Details
 `contract_id    = "<Contract ID>"`

 Powershell command : `Get-Contract -Section "edgercsection-name"`

 `group_id       = "<Group ID>"`
 Powershell command : `Get-Group -Section "edgercsection-name"`

 #### Hostnames you wish to onboard
 `hostnames      = ["<hostname1>", "<hostname2>"]`

 #### Origin Details
 `default_origin = "<Origin Name>"`

 #### Notification Email
 `email          = "<Your Email ID>"`

 #### TLS Settings
 ```
 etls   = true  # Set to true for Enhanced TLS
 certificate_id = "<Certificate ID>"
 ```
 Powershell command : `Get-CPSEnrollment -Section 'edgercsection-name'`. "id" will be the Certificate ID.

 #### Secure by Default Settings
 `secure_by_default = false  # Set to true for SBD cert`

 If `secure_by_default` is true, comment the certificate\_id as SBD doesn't need one.

 **Note:**
 If you want to create a Secure by Default (SBD) certificate:
    1. Set `secure_by_default = true`
    2. Ensure `enhanced_tls` is also set to `true` if you want edgekey.net EHN
    3. Comment the `certificate_id` as SBD does not require one.

 ### Step 3: Run Terraform
 Run the deployment script `../deploy.ps1`. This script is written in PowerShell and acts as an orchestrator for Terraform. It allows to perform individual save and activation actions, it handles the multi-environment directory and files to avoid overwriting the state file. A debug/log mode can also be enabled.

    A common flow is as follows (with "prod" as the environment):
    1. Save the changes only (no activations) using the PM template/product:
    ```bash
    pwsh deploy.ps1 pm -Env prod -Save -Notes "Some user user notes"
    ```

    2. Activate to staging:
    ```bash
    pwsh pm -Env prod -ActivateStaging
    ```

    3. Activate to production:
    ```bash
    pwsh pm -Env prod -ActivateProduction
    ```

    Options:
    * Add the `-Debug` option to the command to log all the Terraform actions in a file stored in the specific environment directory.
    * Add the `-Dry` option to the command to do a dry-run (nothing is applied).
    * You can delete all the resources when you don't need them. Keep in mind some resource can't be deleted in which cases the `terraform destroy` operation will fail as a consequence.
    ```bash
    pwsh deploy.ps1 pm -Env dev -Destroy
```

# Usage
Basic usage of this module is as follows:

```hcl
module "example" {
  	 source  = "<module-location>"
  
	 # Required variables
  	 additional_origins  = <map(object({
    origin_name         = string
    forward_host_header = string
    hostname_match      = list(string)
    path_match          = list(string)
  }))>
  	 contract_id  = <string>
  	 default_origin  = <string>
  	 edgerc_section  = <string>
  	 emails  = <list(string)>
  	 etls  = <bool>
  	 group_id  = <string>
  	 hostnames  = <list(string)>
  	 name  = <string>
  
	 # Optional variables
  	 activate_to_production  = <bool> | default: false
  	 activate_to_staging  = <bool> | default: false
  	 activation_notes  = <string> | default: "activated with terraform"
  	 activation_to_production_exists  = <bool> | default: false
  	 activation_to_staging_exists  = <bool> | default: false
  	 certificate_id  = <number> | default: null
  	 cpcode_name  = <string> | default: null
  	 customer_email  = <string> | default: null
  	 default_cpcode  = <bool> | default: false
  	 edgerc_path  = <string> | default: "~/.edgerc"
  	 ehn_domain  = <string> | default: null
  	 enable_mPulse  = <bool> | default: true
  	 forward_host_header  = <string> | default: "REQUEST_HOST_HEADER"
  	 ip_behavior  = <string> | default: "IPV6_COMPLIANCE"
  	 noncompliance_reason  = <list(string)> | default: []
  	 other_noncompliance_reason  = <string> | default: null
  	 peer_reviewed_by  = <string> | default: null
  	 product_id  = <string> | default: "Site_Accel"
  	 secure_by_default  = <bool> | default: true
  	 sure_route_test_object  = <string> | default: "/akamai/testobject.html"
  	 td_region  = <string> | default: "CH2"
  	 ticket_id  = <string> | default: null
  	 unit_tested  = <bool> | default: null
  	 version_notes  = <string> | default: "Initial Config"
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
| <a name="module_property"></a> [property](#module\_property) | git::ssh://git@github.com/akamai/terraform-templates-modules.git//delivery | v1.3.3 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_origins"></a> [additional\_origins](#input\_additional\_origins) | Additional origins for the property. For now the match is only by hostname. The field forward\_host\_header allows specifying a custom host header for each additional origin.Possible fixed values are ORIGIN\_HOSTNAME or REQUEST\_HOST\_HEADER. But the user can also select any host header they would like to use as a custom value. | <pre>map(object({<br/>    origin_name         = string<br/>    forward_host_header = string<br/>    hostname_match      = list(string)<br/>    path_match          = list(string)<br/>  }))</pre> | n/a | yes |
| <a name="input_contract_id"></a> [contract\_id](#input\_contract\_id) | Contract ID for property/config creation | `string` | n/a | yes |
| <a name="input_default_origin"></a> [default\_origin](#input\_default\_origin) | Default origin server for all properties | `string` | n/a | yes |
| <a name="input_edgerc_section"></a> [edgerc\_section](#input\_edgerc\_section) | Section in the .edgerc file.<br/><br/>    For professional services, it is recommended to create a new section for<br/>    each account managed. | `string` | n/a | yes |
| <a name="input_emails"></a> [emails](#input\_emails) | List or emails for notifications | `list(string)` | n/a | yes |
| <a name="input_etls"></a> [etls](#input\_etls) | Boolean to switch between Enhanced and Standard TLS modes | `bool` | n/a | yes |
| <a name="input_group_id"></a> [group\_id](#input\_group\_id) | Group ID for property/config creation. | `string` | n/a | yes |
| <a name="input_hostnames"></a> [hostnames](#input\_hostnames) | List of hostnames. | `list(string)` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Property name. | `string` | n/a | yes |
| <a name="input_activate_to_production"></a> [activate\_to\_production](#input\_activate\_to\_production) | Set to true to directly activate on the production network. | `bool` | `false` | no |
| <a name="input_activate_to_staging"></a> [activate\_to\_staging](#input\_activate\_to\_staging) | Set to true to directly activate on the staging network. | `bool` | `false` | no |
| <a name="input_activation_notes"></a> [activation\_notes](#input\_activation\_notes) | Activation notes. Leave default value until DXE-2373 is resolved, unless you know what you are doing. | `string` | `"activated with terraform"` | no |
| <a name="input_activation_to_production_exists"></a> [activation\_to\_production\_exists](#input\_activation\_to\_production\_exists) | Do not modify. Flag used together with the logic in the activation resources for the initial activation to production. | `bool` | `false` | no |
| <a name="input_activation_to_staging_exists"></a> [activation\_to\_staging\_exists](#input\_activation\_to\_staging\_exists) | Do not modify. Flag used together with the logic in the activation resources for the initial activation to staging. | `bool` | `false` | no |
| <a name="input_certificate_id"></a> [certificate\_id](#input\_certificate\_id) | Certificate enrollment id. Only applicable if enhanced\_tls is true, and secure\_by\_default<br/>is false.<br/><br/>Can be retrieved using AkamaiPowershell or the Akamai CPS CLI. | `number` | `null` | no |
| <a name="input_cpcode_name"></a> [cpcode\_name](#input\_cpcode\_name) | Default CP Code name. Will be the property name (var.name) if null. | `string` | `null` | no |
| <a name="input_customer_email"></a> [customer\_email](#input\_customer\_email) | Email address of the customer that acknowledged, tested and accepted the change | `string` | `null` | no |
| <a name="input_default_cpcode"></a> [default\_cpcode](#input\_default\_cpcode) | Boolean to enable the default CP Code for all properties. If false, the CP Code must be specified in the property definition. | `bool` | `false` | no |
| <a name="input_edgerc_path"></a> [edgerc\_path](#input\_edgerc\_path) | Path to the .edgerc file. | `string` | `"~/.edgerc"` | no |
| <a name="input_ehn_domain"></a> [ehn\_domain](#input\_ehn\_domain) | EdgeHostname domain, e.g. edgesuite.net or edgekey.net. Will default to one or<br/>the other, based on the value of etls variable. | `string` | `null` | no |
| <a name="input_enable_mPulse"></a> [enable\_mPulse](#input\_enable\_mPulse) | Boolean to decide whether to inject the mpulse behavior | `bool` | `true` | no |
| <a name="input_forward_host_header"></a> [forward\_host\_header](#input\_forward\_host\_header) | Host header to be forwarded to the origin server. Possible fixed values are ORIGIN\_HOSTNAME or REQUEST\_HOST\_HEADER. But the user can also select any host header they would like to use as a custom value. | `string` | `"REQUEST_HOST_HEADER"` | no |
| <a name="input_ip_behavior"></a> [ip\_behavior](#input\_ip\_behavior) | EdgeHostname IP behaviour.Possible values are IPV4 or IPV6\_COMPLIANCE. | `string` | `"IPV6_COMPLIANCE"` | no |
| <a name="input_noncompliance_reason"></a> [noncompliance\_reason](#input\_noncompliance\_reason) | Allowed values for noncompliance\_reason are "NO\_PRODUCTION\_TRAFFIC", "EMERGENCY", "NONE". (OR null for the customer, as None will require the complaince block) | `list(string)` | `[]` | no |
| <a name="input_other_noncompliance_reason"></a> [other\_noncompliance\_reason](#input\_other\_noncompliance\_reason) | Describes the reason why the activation must occur immediately, out of compliance with the standard procedure | `string` | `null` | no |
| <a name="input_peer_reviewed_by"></a> [peer\_reviewed\_by](#input\_peer\_reviewed\_by) | Email address of the peer who performed the review | `string` | `null` | no |
| <a name="input_product_id"></a> [product\_id](#input\_product\_id) | Property Manager product. [ION - Fresca] | `string` | `"Site_Accel"` | no |
| <a name="input_secure_by_default"></a> [secure\_by\_default](#input\_secure\_by\_default) | Secure by default. Set to true to use the DEFAULT certificate provisioning type.<br/><br/>This is the easiest for automation, because Akamai takes care of provisioning the certificate<br/>using a Let's Encrypt DV SAN in a fully managed way.<br/><br/>If the customer requires an OV SAN, or Secure by Default is inapplicable for whatever<br/>other reason, set this to false. | `bool` | `true` | no |
| <a name="input_sure_route_test_object"></a> [sure\_route\_test\_object](#input\_sure\_route\_test\_object) | Test object path for SureRoute | `string` | `"/akamai/testobject.html"` | no |
| <a name="input_td_region"></a> [td\_region](#input\_td\_region) | Region (map) for Tiered Distribution behaviour. Only applies if network is Standard TLS.<br/>Options are: CH2, CHAPAC, CHEU2, CHEUS2, CHWUS2, CHCUS2, CHAUS | `string` | `"CH2"` | no |
| <a name="input_ticket_id"></a> [ticket\_id](#input\_ticket\_id) | Identifies the ticket that describes the need for the activation | `string` | `null` | no |
| <a name="input_unit_tested"></a> [unit\_tested](#input\_unit\_tested) | Whether the metadata to activate has been fully tested | `bool` | `null` | no |
| <a name="input_version_notes"></a> [version\_notes](#input\_version\_notes) | Property version notes. | `string` | `"Initial Config"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cert_status"></a> [cert\_status](#output\_cert\_status) | The status of the certificate, which may include any challenge required to generate it (DNS CNAME or other type) |
| <a name="output_cpcode_id"></a> [cpcode\_id](#output\_cpcode\_id) | The CP Code's unique identifier. |
| <a name="output_property_id"></a> [property\_id](#output\_property\_id) | The property's unique identifier. |
| <a name="output_rules_errors"></a> [rules\_errors](#output\_rules\_errors) | The contents of errors field returned by the API. |
<!-- END_TF_DOCS -->