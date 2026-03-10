## ----------------------------------------------------------------------------
# Provider auth (Akamai EdgeGrid)
## ----------------------------------------------------------------------------
edgerc_path    = "~/.edgerc" // path to ederc file, if not default ~/.edgerc
edgerc_section = "default" // your section name if not default

## ----------------------------------------------------------------------------
# Zone settings
## ----------------------------------------------------------------------------
zone_name   = "zone-name" # your zone name
contract_id = "ctr_X-XXX" # your contract ID
group_id    = "grp_XXX"   # your group ID
zone_type   = "PRIMARY" # PRIMARY | SECONDARY

## ----------------------------------------------------------------------------
# SOA (managed only if not null)
## ----------------------------------------------------------------------------

# soa = {
#   email        = "admin.example.com."  # mailbox with dot instead of @
#   name_server  = "a1-91.akam.net."     # primary NS (mname)
#   ttl          = 3600
#   refresh      = 3600
#   retry        = 600
#   expiry       = 604800
#   nxdomain_ttl = 300
# }

## ----------------------------------------------------------------------------
# Basic records
## ----------------------------------------------------------------------------
# a_records = [
#   { name = "www", target = ["96.6.114.83"], ttl = 300 },
#   { name = "@",   target = ["72.246.2.76"], ttl = 300 },
# ]

# aaaa_records = [
#   { name = "www", target = ["2001:db8:85a3::8a2e:370:7334"], ttl = 300 },
# ]

# cname_records = [
#   { name = "blog", target = ["your.cname.target.name."], ttl = 300 },
#   { name = "cdn",  target = ["edge.example-cdn.net."],   ttl = 300 },
# ]

# txt_records = [
#   { name = "@",        target = ["v=spf1 include:_spf.google.com ~all"], ttl = 3600 },
#   { name = "_dmarc",   target = ["v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com"], ttl = 3600 },
#   { name = "_acme-challenge", target = ["your-verification-code"], ttl = 300 },
# ]

# ns_records = [
#   # Apex NS — typically Akamai authorities for Edge DNS
#   { name = "@", ttl = 300, target = [
#       "a1-91.akam.net.",
#       "a13-64.akam.net.",
#       "a20-65.akam.net.",
#       "a22-66.akam.net.",
#       "a24-67.akam.net.",
#       "a9-64.akam.net.",
#   ]},
#   # Subdomain delegation example
#   { name = "dev", ttl = 300, target = [
#       "ns1.customdns.net.",
#       "ns2.customdns.net.",
#   ]},
# ]

# ptr_records = [
#   { name = "10.2.0.192.in-addr.arpa", target = ["host-10.example.com."], ttl = 3600 },
# ]

# loc_records = [
#   { name = "hq", target = ["52 13 12.000 N 21 00 30.000 E 12.00m 10.00m 2.00m 2.00m"], ttl = 3600 },
# ]

# spf_records = [
#   { name = "@", target = ["v=spf1 ip4:192.0.2.0/24 include:_spf.example.net ~all"], ttl = 3600 },
# ]

# rp_records = [
#   { name = "postmaster", mailbox = "postmaster.example.com.", txt = "hostmaster.example.com.", ttl = 3600 },
# ]

# hinfo_records = [
#   { name = "host1", hardware = "Intel-64", software = "Linux", ttl = 3600 },
# ]


## ----------------------------------------------------------------------------
# Advanced records
## ----------------------------------------------------------------------------
# mx_records = [
#   { name = "@", target = ["mx1.example.com."], ttl = 3600, priority = 10 },
#   { name = "test", target = ["mx2.example.com."], ttl = 3600, priority = 20, priority_increment = 1 },
# ]

# srv_records = [
#   { name = "_sip._tcp", target = ["sipserver.example.com."], ttl = 3600, priority = 10, weight = 50, port = 5060 },
# ]

# caa_records = [
#   { name = "@", target = ["0 issue \"letsencrypt.org\""], ttl = 3600 },
# ]