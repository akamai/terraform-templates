output "txt_validation_challenges" {
  description = "Map of domain_name => TXT record value to publish in DNS."
  value       = module.dom_validation.txt_validation_challenges
}

output "cname_validation_challenges" {
  description = "Map of domain_name => CNAME record value to publish in DNS."
  value       = module.dom_validation.cname_validation_challenges
}

output "validation_entries" {
  description = "Configured domain validation entries (domain_name, validation_scope, validation_method)."
  value = [
    for entry in var.domain_validation_entries : {
      domain_name       = entry.domain_name
      validation_scope  = upper(entry.validation_scope)
      validation_method = entry.validation_method
    }
  ]
}

output "domain_search_results" {
  description = "Results of the domain ownership search (null when domain_search_entries is empty)."
  value       = module.dom_validation.domain_search_results
}
