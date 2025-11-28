output "property_id" {
  value       = module.property.property_id
  description = "The property's unique identifier."
}

output "rules_errors" {
  value       = module.property.rules_errors
  description = "The contents of errors field returned by the API."
}

output "cpcode_id" {
  value       = module.property.cpcode_id
  description = "The CP Code's unique identifier."
}

output "cert_status" {
  value       = module.property.cert_status
  description = "The status of the certificate, which may include any challenge required to generate it (DNS CNAME or other type)"
}