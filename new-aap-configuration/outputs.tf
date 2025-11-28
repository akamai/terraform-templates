output "config_id" {
  value       = module.security.config_id
  description = "Security Configuration ID"
}

output "security_policy_id" {
  value       = module.security.security_policy_id
  description = "Security Policy ID"
}

output "rate" {
  value       = module.security.rate
  description = "Rate Policy IDs"
}
