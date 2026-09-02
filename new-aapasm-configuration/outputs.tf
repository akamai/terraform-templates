output "config_id" {
  value       = module.security-config.config_id
  description = "Security Configuration ID"
}

output "security_policy_ids" {
  value       = { for key, pol in module.security-policy : key => pol.security_policy_id }
  description = "Map of policy keys to their Security Policy IDs"
}
