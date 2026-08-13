terraform {
  # Terraform 1.5+ required for declarative import block support
  required_version = ">= 1.5"
  required_providers {
    akamai = {
      source  = "akamai/akamai"
      version = "~> 10.0" # Use Akamai Provider 10.0 or higher for DOM support
    }
  }
}