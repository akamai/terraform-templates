# Read Akamai credentials from .edgerc file
provider "akamai" {
  edgerc         = var.edgerc_path
  config_section = var.edgerc_section
}

# Uncomment below block if using env variables for the API credentials
# provider "akamai" {
#   config {
#     client_secret = var.akamai_client_secret
#     host          = var.akamai_host
#     access_token  = var.akamai_access_token
#     client_token  = var.akamai_client_token
#     account_key   = var.akamai_account_key
#   }
# }
