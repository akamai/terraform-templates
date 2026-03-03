output "api1" {
  value = module.api_definition
}

output "config_id" {
  description = "Akamai AppSec configuration ID resolved by name"
  value       = module.transactional_endpoint["api1"].config_id
}