<!-- BEGIN_TF_DOCS -->

# Module: new-edns (Akamai Edge DNS)

This module provisions and manages **Akamai Edge DNS (EDNS)** zones using Terraform.
It supports both **PRIMARY** and **SECONDARY** DNS zones and provides full lifecycle
management of DNS records for PRIMARY zones.

The module is designed to be consumed by higher-level templates
(for example: ps-terraform-templates) and follows the same documentation
and automation standards as other official PS Terraform modules.

---

## Authentication

This module uses **Akamai EdgeGrid authentication**.

Please refer to:
[DevOps Harmony / Setting up OpenAPI/EdgeGrid for PS]
(https://collaborate.akamai.com/confluence/pages/viewpage.action?pageId=748278616)

Authentication details are provided via:
- `.edgerc` file
- `edgerc_section` variable

---

## Supported Zone Types

### PRIMARY
- Creates a new authoritative DNS zone in Akamai Edge DNS
- Allows full management of DNS records
- Optional SOA record management
- Automatically retrieves Akamai authoritative nameservers

### SECONDARY
- Creates a secondary (slave) DNS zone
- Requires master server IPs (`masters`)
- Optional TSIG configuration for zone transfers
- DNS records are **not managed** (replicated from the master)

---

## Managed Resources

- `akamai_dns_zone`
- `akamai_dns_record` (multiple types, PRIMARY only)
- `akamai_authorities_set` (authoritative NS discovery)
- `time_sleep` (SOA propagation wait)

---

## Usage

Basic usage of this module:

```hcl
module "edns" {
  source = "git::ssh://git@git.source.akamai.com:7999/gss-devops/ps-terraform-templates-modules.git//new-edns?ref=vX.Y.Z"

  contract_id = "ctr_XXXX"
  group_id    = "grp_XXXX"

  zone_name = "example.com"
  zone_type = "primary"
}
```

---

## PRIMARY Zone – DNS Records

When `zone_type = "primary"`, DNS records can be managed by uncommenting
and populating the corresponding variables in `terraform.tfvars`.

Supported record types include:

- A
- AAAA
- CNAME
- TXT
- NS
- MX
- SRV
- CAA
- PTR
- LOC
- SPF
- RP

Each record type is defined as a list of objects.
If a list is empty, no records of that type are created.

---

## SOA Management (PRIMARY only)

SOA record management is optional.

- If `soa = null` → SOA is not managed by Terraform
- If `soa` is provided → SOA is explicitly created/updated

The module also reads back the SOA record after zone creation
and exposes both raw and parsed values as outputs.

---

## SECONDARY Zone – Masters & TSIG

For `zone_type = "secondary"`:

- `masters` must contain at least one IP address
- Optional TSIG authentication can be configured using `tsig_key`

DNS records are **not created** for secondary zones.

---

## Nameservers (NS)

The module automatically retrieves the **Akamai authoritative nameservers**
assigned to the contract.

Outputs include:
- Akamai authoritative NS (FQDNs)
- IPv4 addresses resolved for those NS

These outputs can be used to:
- Configure delegation at a parent DNS provider
- Populate `masters` for SECONDARY zones
- Generate ready-to-paste tfvars snippets

Custom NS records can also be provided explicitly via `ns_records`
(PRIMARY zones only).

---

## Outputs

The module exposes outputs for:

- Zone name and type
- Raw and parsed SOA (PRIMARY)
- Akamai authoritative nameservers
- Nameserver IPv4 addresses
- Configured SECONDARY masters

---

# Usage
Basic usage of this module is as follows:

```hcl
module "example" {
  	 source  = "<module-location>"
  
	 # Required variables
  	 contract_id  = <string>
  	 group_id  = <string>
  	 zone_name  = <string>
  	 zone_type  = <string>
  
	 # Optional variables
  	 a_records  = <list(object({
    name   = string
    target = list(string)
    ttl    = number
  }))> | default: []
  	 aaaa_records  = <list(object({
    name   = string
    target = list(string)
    ttl    = number
  }))> | default: []
  	 caa_records  = <list(object({
    name   = string
    target = list(string)
    ttl    = number
  }))> | default: []
  	 cname_records  = <list(object({
    name   = string
    target = list(string)
    ttl    = number
  }))> | default: []
  	 destroy_mode  = <bool> | default: false
  	 edgerc_path  = <string> | default: null
  	 edgerc_section  = <string> | default: null
  	 force_empty_records  = <bool> | default: false
  	 hinfo_records  = <list(object({
    name     = string
    hardware = string
    software = string
    ttl      = number
  }))> | default: []
  	 loc_records  = <list(object({
    name   = string
    target = list(string)
    ttl    = number
  }))> | default: []
  	 masters  = <list(string)> | default: []
  	 mx_records  = <list(object({
    name               = string
    target             = list(string)
    ttl                = number
    priority           = optional(number)
    priority_increment = optional(number)
  }))> | default: []
  	 ns_records  = <list(object({
    name   = string
    target = list(string)
    ttl    = number
  }))> | default: []
  	 ptr_records  = <list(object({
    name   = string
    target = list(string)
    ttl    = number
  }))> | default: []
  	 rp_records  = <list(object({
    name    = string
    mailbox = string
    txt     = string
    ttl     = number
  }))> | default: []
  	 soa  = <object({
    email        = string
    name_server  = string
    ttl          = number
    refresh      = number
    retry        = number
    expiry       = number
    nxdomain_ttl = number
  })> | default: null
  	 spf_records  = <list(object({
    name   = string
    target = list(string)
    ttl    = number
  }))> | default: []
  	 srv_records  = <list(object({
    name     = string
    target   = list(string)
    ttl      = number
    priority = number
    weight   = number
    port     = number
  }))> | default: []
  	 tsig_key  = <object({
    name      = string
    algorithm = string
    secret    = string
  })> | default: null
  	 txt_records  = <list(object({
    name   = string
    target = list(string)
    ttl    = number
  }))> | default: []
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_akamai"></a> [akamai](#requirement\_akamai) | ~> 9.2 |
| <a name="requirement_dns"></a> [dns](#requirement\_dns) | ~> 3.4 |

## Resources

No resources.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_edns"></a> [edns](#module\_edns) | git::ssh://git@github.com/akamai/terraform-templates-modules.git//edns | v1.3.3 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_contract_id"></a> [contract\_id](#input\_contract\_id) | Akamai contract ID | `string` | n/a | yes |
| <a name="input_group_id"></a> [group\_id](#input\_group\_id) | Akamai group ID | `string` | n/a | yes |
| <a name="input_zone_name"></a> [zone\_name](#input\_zone\_name) | DNS zone name (e.g. example.com) | `string` | n/a | yes |
| <a name="input_zone_type"></a> [zone\_type](#input\_zone\_type) | Zone type: PRIMARY or SECONDARY | `string` | n/a | yes |
| <a name="input_a_records"></a> [a\_records](#input\_a\_records) | n/a | <pre>list(object({<br/>    name   = string<br/>    target = list(string)<br/>    ttl    = number<br/>  }))</pre> | `[]` | no |
| <a name="input_aaaa_records"></a> [aaaa\_records](#input\_aaaa\_records) | n/a | <pre>list(object({<br/>    name   = string<br/>    target = list(string)<br/>    ttl    = number<br/>  }))</pre> | `[]` | no |
| <a name="input_caa_records"></a> [caa\_records](#input\_caa\_records) | n/a | <pre>list(object({<br/>    name   = string<br/>    target = list(string)<br/>    ttl    = number<br/>  }))</pre> | `[]` | no |
| <a name="input_cname_records"></a> [cname\_records](#input\_cname\_records) | n/a | <pre>list(object({<br/>    name   = string<br/>    target = list(string)<br/>    ttl    = number<br/>  }))</pre> | `[]` | no |
| <a name="input_destroy_mode"></a> [destroy\_mode](#input\_destroy\_mode) | n/a | `bool` | `false` | no |
| <a name="input_edgerc_path"></a> [edgerc\_path](#input\_edgerc\_path) | Path to the .edgerc file. | `string` | `null` | no |
| <a name="input_edgerc_section"></a> [edgerc\_section](#input\_edgerc\_section) | Section in the .edgerc file.<br/><br/>    For professional services, it is recommended to create a new section for<br/>    each account managed. | `string` | `null` | no |
| <a name="input_force_empty_records"></a> [force\_empty\_records](#input\_force\_empty\_records) | Force all DNS record lists to be empty (used for safe destroy) | `bool` | `false` | no |
| <a name="input_hinfo_records"></a> [hinfo\_records](#input\_hinfo\_records) | n/a | <pre>list(object({<br/>    name     = string<br/>    hardware = string<br/>    software = string<br/>    ttl      = number<br/>  }))</pre> | `[]` | no |
| <a name="input_loc_records"></a> [loc\_records](#input\_loc\_records) | n/a | <pre>list(object({<br/>    name   = string<br/>    target = list(string)<br/>    ttl    = number<br/>  }))</pre> | `[]` | no |
| <a name="input_masters"></a> [masters](#input\_masters) | Master DNS server IPs for SECONDARY zone | `list(string)` | `[]` | no |
| <a name="input_mx_records"></a> [mx\_records](#input\_mx\_records) | n/a | <pre>list(object({<br/>    name               = string<br/>    target             = list(string)<br/>    ttl                = number<br/>    priority           = optional(number)<br/>    priority_increment = optional(number)<br/>  }))</pre> | `[]` | no |
| <a name="input_ns_records"></a> [ns\_records](#input\_ns\_records) | n/a | <pre>list(object({<br/>    name   = string<br/>    target = list(string)<br/>    ttl    = number<br/>  }))</pre> | `[]` | no |
| <a name="input_ptr_records"></a> [ptr\_records](#input\_ptr\_records) | n/a | <pre>list(object({<br/>    name   = string<br/>    target = list(string)<br/>    ttl    = number<br/>  }))</pre> | `[]` | no |
| <a name="input_rp_records"></a> [rp\_records](#input\_rp\_records) | n/a | <pre>list(object({<br/>    name    = string<br/>    mailbox = string<br/>    txt     = string<br/>    ttl     = number<br/>  }))</pre> | `[]` | no |
| <a name="input_soa"></a> [soa](#input\_soa) | SOA record configuration (null = unmanaged) | <pre>object({<br/>    email        = string<br/>    name_server  = string<br/>    ttl          = number<br/>    refresh      = number<br/>    retry        = number<br/>    expiry       = number<br/>    nxdomain_ttl = number<br/>  })</pre> | `null` | no |
| <a name="input_spf_records"></a> [spf\_records](#input\_spf\_records) | n/a | <pre>list(object({<br/>    name   = string<br/>    target = list(string)<br/>    ttl    = number<br/>  }))</pre> | `[]` | no |
| <a name="input_srv_records"></a> [srv\_records](#input\_srv\_records) | n/a | <pre>list(object({<br/>    name     = string<br/>    target   = list(string)<br/>    ttl      = number<br/>    priority = number<br/>    weight   = number<br/>    port     = number<br/>  }))</pre> | `[]` | no |
| <a name="input_tsig_key"></a> [tsig\_key](#input\_tsig\_key) | Optional TSIG key for zone transfers (SECONDARY only) | <pre>object({<br/>    name      = string<br/>    algorithm = string<br/>    secret    = string<br/>  })</pre> | `null` | no |
| <a name="input_txt_records"></a> [txt\_records](#input\_txt\_records) | n/a | <pre>list(object({<br/>    name   = string<br/>    target = list(string)<br/>    ttl    = number<br/>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_akamai_authorities_only"></a> [akamai\_authorities\_only](#output\_akamai\_authorities\_only) | Authoritative nameservers assigned by Akamai (FQDNs) |
| <a name="output_authorities_plus_custom_ns"></a> [authorities\_plus\_custom\_ns](#output\_authorities\_plus\_custom\_ns) | Union of Akamai authoritative NS and any custom NS targets (FQDNs) |
| <a name="output_authorities_plus_custom_ns_ips"></a> [authorities\_plus\_custom\_ns\_ips](#output\_authorities\_plus\_custom\_ns\_ips) | Map: NS hostname => list of resolved IPv4/IPv6 addresses |
| <a name="output_delegation_ns_tfvars_snippet"></a> [delegation\_ns\_tfvars\_snippet](#output\_delegation\_ns\_tfvars\_snippet) | Ready-to-paste tfvars snippet for apex NS delegation |
| <a name="output_secondary_masters_tfvars_snippet"></a> [secondary\_masters\_tfvars\_snippet](#output\_secondary\_masters\_tfvars\_snippet) | Ready-to-paste tfvars snippet for SECONDARY masters |
| <a name="output_zone_name"></a> [zone\_name](#output\_zone\_name) | DNS zone name |
| <a name="output_zone_soa_parsed"></a> [zone\_soa\_parsed](#output\_zone\_soa\_parsed) | Parsed SOA fields (PRIMARY only) |
| <a name="output_zone_soa_raw"></a> [zone\_soa\_raw](#output\_zone\_soa\_raw) | Raw SOA RDATA string from the apex (PRIMARY only) |
| <a name="output_zone_transfer_masters"></a> [zone\_transfer\_masters](#output\_zone\_transfer\_masters) | Configured master server IPs for SECONDARY zones |
| <a name="output_zone_type"></a> [zone\_type](#output\_zone\_type) | DNS zone type (PRIMARY or SECONDARY) |
<!-- END_TF_DOCS -->