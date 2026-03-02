output "zone_name" {
  description = "DNS zone name"
  value       = var.zone_name
}
output "zone_type" {
  description = "DNS zone type (PRIMARY or SECONDARY)"
  value       = upper(var.zone_type)
}

## ----------------------------------------------------------------------------
# SOA (from Akamai API via module)
## ----------------------------------------------------------------------------

output "zone_soa_raw" {
  description = "Raw SOA RDATA string from the apex (PRIMARY only)"
  value       = module.edns.zone_soa_raw
}

output "zone_soa_parsed" {
  description = "Parsed SOA fields (PRIMARY only)"
  value       = module.edns.zone_soa_parsed
}

## ----------------------------------------------------------------------------
# Nameservers (Akamai authorities + custom NS if any)
## ----------------------------------------------------------------------------

output "authorities_plus_custom_ns" {
  description = "Union of Akamai authoritative NS and any custom NS targets (FQDNs)"
  value       = module.edns.authorities_plus_custom_ns
}

output "akamai_authorities_only" {
  description = "Authoritative nameservers assigned by Akamai (FQDNs)"
  value       = module.edns.akamai_authorities_only
}

## ----------------------------------------------------------------------------
# Nameserver IPs (for SECONDARY masters / ACLs)
## ----------------------------------------------------------------------------

output "authorities_plus_custom_ns_ips" {
  description = "Map: NS hostname => list of resolved IPv4/IPv6 addresses"
  value       = module.edns.authorities_plus_custom_ns_ips
}

## ----------------------------------------------------------------------------
# SECONDARY-specific
## ----------------------------------------------------------------------------

output "zone_transfer_masters" {
  description = "Configured master server IPs for SECONDARY zones"
  value       = module.edns.zone_transfer_masters
}

## ----------------------------------------------------------------------------
# Helper snippets
## ----------------------------------------------------------------------------

output "secondary_masters_tfvars_snippet" {
  description = "Ready-to-paste tfvars snippet for SECONDARY masters"
  value = format(
    "masters = [%s]",
    join(
      ", ",
      [
        for ip in distinct(flatten(values(module.edns.authorities_plus_custom_ns_ips))) :
        format("\"%s\"", ip)
      ]
    )
  )
}

output "delegation_ns_tfvars_snippet" {
  description = "Ready-to-paste tfvars snippet for apex NS delegation"
  value = format(
    "ns_records = [{ name = \"@\", ttl = 300, target = [%s] }]",
    join(
      ", ",
      [
        for ns in module.edns.akamai_authorities_only :
        format("\"%s\"", ns)
      ]
    )
  )
}
