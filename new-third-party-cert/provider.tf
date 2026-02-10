terraform {
  required_providers {
    akamai = {
      source  = "akamai/akamai"
      version = "9.1.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.6"
    }

  }
  required_version = ">= 1.9.0"
}

provider "akamai" {
  edgerc         = var.edgerc_path
  config_section = var.edgerc_section
}