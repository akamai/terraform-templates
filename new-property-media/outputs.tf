output "property_id" {
  value       = module.property.property_id
  description = "The property's unique identifier."
}

output "rule_errors" {
  value       = module.property.rule_errors
  description = "Validation errors returned by Property Manager for the rendered rule tree, if any."
}

output "cpcode_id" {
  value       = module.property.cpcode_id
  description = "The CP Code's unique identifier."
}

output "cert_status" {
  value       = module.property.cert_status
  description = "Hostname-to-edge-hostname mapping with certificate provisioning type, for reference."
}
