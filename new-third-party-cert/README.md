<!-- BEGIN_TF_DOCS -->

# Akamai CPS Third-Party Certificate Module

This Terraform configuration manages Akamai Certificate Provisioning System (CPS) third-party certificate enrollments. Handles both enrollment (creating a new certificate request) and certificate upload.
It supports:

## Two-phase workflow in Terraform when dealing with Third-Party signed certificates:

### Phase 1 → Terraform creates the enrollment + CSR.
- Creating an enrollment with certificate details (SANs, contacts, CSR, network config, etc.)
- You take the CSR, submit to a CA, and later come back with the signed cert.

### Phase 2 → Terraform uploads the signed certificate to Akamai.
- Uploading RSA or ECDSA certificates and their trust chains in pem format

## Prerequisites

- Terraform v1.9+
- Akamai Terraform Provider
- An Akamai .edgerc file with valid credentials

## Project Structure
```
.
├── [main.tf]              # Root module calling the CPS enrollment module
├── [variables.tf]         # Input variables definition
├── [terraform.tfvars]     # User-supplied variable values
├── [files.tf]             # Generates CSR files for ECDSA and RSA certificates  
├── [providers.tf]         # Akamai provider configuration
└── [csr_ecdsa.pem]        # Generated ECDSA CSR (auto-generated)
└── [csr_rsa.pem]          # Generated RSA CSR (auto-generated)
```

## Scenario 1: Create a New Enrollment`

If you are creating certificate for the first time, you will create an enrollment with your domain details with the help of tfvars.

## Scenario 2: Upload a Certificate to an Existing Enrollment

Once an enrollment exists/created, you can upload your RSA/ ECDSA cert and trust chain.
````
enrollment_id = 12345

certificate_rsa_pem   = file("rsa_certificate.pem")
trust_chain_rsa_pem   = file("rsa_certificate_ca.pem")
certificate_ecdsa_pem = ""
trust_chain_ecdsa_pem = ""
```
- This attaches your certificate to the given enrollment and deploys it to the Akamai edge.

**Please note**

1. `change_management`
    1. Purpose: Enables Akamai Change Management workflow (review/approve before deployment).
    2. If `true` changes are put into Change Management pending state until manually approved.
    3. If `false`  changes go straight through without requiring Change Management approval.     

2. `acknowledge_post_verification_warnings`
    1. Purpose: After CPS runs verification (DNS checks, certificate validation, etc.), it may raise warnings.
    2. If `true`: it indicates that you acknowledge the post-verification warnings and confirm proceeding with the deployment
    3. If `false`: deployment halts until warnings are reviewed/cleared.

3. If only one type (RSA or ECDSA) is used, leave the other’s fields blank.

# Usage
Basic usage of this module is as follows:

```hcl
module "example" {
  	 source  = "<module-location>"
  
	 # Required variables
  	 admin_contact  = <object({
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
  })>
  	 cert_name  = <string>
  	 certificate_ecdsa_pem  = <string>
  	 certificate_rsa_pem  = <string>
  	 common_name  = <string>
  	 contract_id  = <string>
  	 csr  = <object({
    country_code        = string
    city                = string
    organization        = string
    organizational_unit = string
    state               = string
  })>
  	 edgerc_section  = <string>
  	 enrollment_id  = <number>
  	 network_configuration  = <object({
    disallowed_tls_versions = list(string)
    clone_dns_names         = bool
    geography               = string
    must_have_ciphers       = string
    ocsp_stapling           = string
    preferred_ciphers       = string
    quic_enabled            = bool
  })>
  	 organization  = <object({
    name             = string
    phone            = string
    address_line_one = string
    address_line_two = string
    city             = string
    region           = string
    postal_code      = string
    country_code     = string
  })>
  	 sans  = <list(string)>
  	 tech_contact  = <object({
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
  })>
  	 trust_chain_ecdsa_pem  = <string>
  	 trust_chain_rsa_pem  = <string>
  
	 # Optional variables
  	 acknowledge_change_management  = <bool> | default: false
  	 acknowledge_post_verification_warnings  = <bool> | default: false
  	 acknowledge_pre_verification_warnings  = <bool> | default: false
  	 allow_duplicate_common_name  = <bool> | default: false
  	 auto_approve_warnings  = <list(string)> | default: []
  	 change_management  = <bool> | default: false
  	 edgerc_path  = <string> | default: "~/.edgerc"
  	 secure_network  = <string> | default: "standard-tls"
  	 signature_algorithm  = <string> | default: ""
  	 sni_only  = <bool> | default: true
  	 wait_for_deployment  = <bool> | default: false
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_akamai"></a> [akamai](#requirement\_akamai) | ~> 9.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.6 |

## Resources

| Name | Type |
|------|------|
| [local_file.csr_ecdsa_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.csr_rsa_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_third-party-cert"></a> [third-party-cert](#module\_third-party-cert) | git::ssh://git@github.com/akamai/terraform-templates-modules.git//third-party-cert | v1.3.3 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_contact"></a> [admin\_contact](#input\_admin\_contact) | Admin contact details | <pre>object({<br/>    first_name       = string<br/>    last_name        = string<br/>    organization     = string<br/>    email            = string<br/>    phone            = string<br/>    address_line_one = string<br/>    address_line_two = string<br/>    city             = string<br/>    region           = string<br/>    postal_code      = string<br/>    country_code     = string<br/>  })</pre> | n/a | yes |
| <a name="input_cert_name"></a> [cert\_name](#input\_cert\_name) | Certificate name / identifier (e.g. cert1) | `string` | n/a | yes |
| <a name="input_certificate_ecdsa_pem"></a> [certificate\_ecdsa\_pem](#input\_certificate\_ecdsa\_pem) | ECDSA certificate PEM string | `string` | n/a | yes |
| <a name="input_certificate_rsa_pem"></a> [certificate\_rsa\_pem](#input\_certificate\_rsa\_pem) | RSA certificate PEM string | `string` | n/a | yes |
| <a name="input_common_name"></a> [common\_name](#input\_common\_name) | Primary certificate common name | `string` | n/a | yes |
| <a name="input_contract_id"></a> [contract\_id](#input\_contract\_id) | Akamai contract ID | `string` | n/a | yes |
| <a name="input_csr"></a> [csr](#input\_csr) | CSR details | <pre>object({<br/>    country_code        = string<br/>    city                = string<br/>    organization        = string<br/>    organizational_unit = string<br/>    state               = string<br/>  })</pre> | n/a | yes |
| <a name="input_edgerc_section"></a> [edgerc\_section](#input\_edgerc\_section) | Section in the .edgerc file.<br/><br/>    For professional services, it is recommended to create a new section for<br/>    each account managed. | `string` | n/a | yes |
| <a name="input_enrollment_id"></a> [enrollment\_id](#input\_enrollment\_id) | Enrollment ID for the uploaded certificate | `number` | n/a | yes |
| <a name="input_network_configuration"></a> [network\_configuration](#input\_network\_configuration) | Network configuration for enrollment | <pre>object({<br/>    disallowed_tls_versions = list(string)<br/>    clone_dns_names         = bool<br/>    geography               = string<br/>    must_have_ciphers       = string<br/>    ocsp_stapling           = string<br/>    preferred_ciphers       = string<br/>    quic_enabled            = bool<br/>  })</pre> | n/a | yes |
| <a name="input_organization"></a> [organization](#input\_organization) | Organization details | <pre>object({<br/>    name             = string<br/>    phone            = string<br/>    address_line_one = string<br/>    address_line_two = string<br/>    city             = string<br/>    region           = string<br/>    postal_code      = string<br/>    country_code     = string<br/>  })</pre> | n/a | yes |
| <a name="input_sans"></a> [sans](#input\_sans) | Subject Alternative Names for the certificate | `list(string)` | n/a | yes |
| <a name="input_tech_contact"></a> [tech\_contact](#input\_tech\_contact) | Technical contact details | <pre>object({<br/>    first_name       = string<br/>    last_name        = string<br/>    organization     = string<br/>    email            = string<br/>    phone            = string<br/>    address_line_one = string<br/>    city             = string<br/>    region           = string<br/>    postal_code      = string<br/>    country_code     = string<br/>  })</pre> | n/a | yes |
| <a name="input_trust_chain_ecdsa_pem"></a> [trust\_chain\_ecdsa\_pem](#input\_trust\_chain\_ecdsa\_pem) | ECDSA trust chain PEM string | `string` | n/a | yes |
| <a name="input_trust_chain_rsa_pem"></a> [trust\_chain\_rsa\_pem](#input\_trust\_chain\_rsa\_pem) | RSA trust chain PEM string | `string` | n/a | yes |
| <a name="input_acknowledge_change_management"></a> [acknowledge\_change\_management](#input\_acknowledge\_change\_management) | Acknowledge change management for certificate upload | `bool` | `false` | no |
| <a name="input_acknowledge_post_verification_warnings"></a> [acknowledge\_post\_verification\_warnings](#input\_acknowledge\_post\_verification\_warnings) | Acknowledge post-verification warnings | `bool` | `false` | no |
| <a name="input_acknowledge_pre_verification_warnings"></a> [acknowledge\_pre\_verification\_warnings](#input\_acknowledge\_pre\_verification\_warnings) | Acknowledge pre-verification warnings | `bool` | `false` | no |
| <a name="input_allow_duplicate_common_name"></a> [allow\_duplicate\_common\_name](#input\_allow\_duplicate\_common\_name) | Whether duplicate common names are allowed | `bool` | `false` | no |
| <a name="input_auto_approve_warnings"></a> [auto\_approve\_warnings](#input\_auto\_approve\_warnings) | List of warnings to auto-approve | `list(string)` | `[]` | no |
| <a name="input_change_management"></a> [change\_management](#input\_change\_management) | Enable/disable change management | `bool` | `false` | no |
| <a name="input_edgerc_path"></a> [edgerc\_path](#input\_edgerc\_path) | ------------------------ Enrollment Variables ------------------------ | `string` | `"~/.edgerc"` | no |
| <a name="input_secure_network"></a> [secure\_network](#input\_secure\_network) | TLS network setting | `string` | `"standard-tls"` | no |
| <a name="input_signature_algorithm"></a> [signature\_algorithm](#input\_signature\_algorithm) | Signature algorithm for CSR | `string` | `""` | no |
| <a name="input_sni_only"></a> [sni\_only](#input\_sni\_only) | Enable SNI-only certificates | `bool` | `true` | no |
| <a name="input_wait_for_deployment"></a> [wait\_for\_deployment](#input\_wait\_for\_deployment) | Wait for deployment to complete before proceeding | `bool` | `false` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->