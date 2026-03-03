# =================================================
# Provider / Authentication
# =================================================

# Path to your local .edgerc file
edgerc_path = "~/.edgerc"

# Section inside .edgerc to use for authentication
# Must contain client_token, client_secret, access_token, host
edgerc_section = "services"

# Akamai group name (must match exactly)
# Format usually: "<Group Name>-<ContractId>"
group_name = "Akamai Professional Services-1-1NC95D"



# =================================================
# API Definitions
# =================================================

# Map of API identifiers to OpenAPI specification files
# Key must match between 'apis' and 'operations'
apis = {
  api1 = "api1.yml"
  api2 = "api2.yml"
  # api3 = "api3.json"
}

# Map of API identifiers to operations definition files
# Must correspond 1:1 with 'apis'
operations = {
  api1 = "operations-api.json"
  api2 = "operations-api2.json"
  # api3 = "operations-api3.json"
}



# =================================================
# Security Configuration
# =================================================

# Existing AppSec configuration name
config_name = "Sharks1232"

# Security policy name inside the above configuration
policy_name = "tf-demo"



# =================================================
# Bot Manager – JavaScript Injection
# =================================================

# Hostnames where JavaScript injection rule should apply
javascript_hostnames = [
  "sharath.gslab-akashop.com"
]

# Injection behavior:
#   NEVER
#   AROUND_PROTECTED_OPERATIONS
#   ALWAYS
injection_type = "ALWAYS"



# =================================================
# Telemetry Expectations
# =================================================

# Indicates expected traffic types for transactional endpoint logic

# Inline
expect_inline_traffic = true

# SDK-based traffic 
expect_sdk_traffic = true

# Standard traffic
expect_standard_traffic = false