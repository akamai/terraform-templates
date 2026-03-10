terraform {
  required_providers {
    akamai = {
      source  = "akamai/akamai"
      version = "~> 9.2"
    }

    time = {
      source = "hashicorp/time"
    }
    dns = {
      source  = "hashicorp/dns"
      version = "~> 3.4"
    }
  }
  required_version = ">= 1.9.0"
  backend "local" {}
}
provider "akamai" {
  edgerc         = var.edgerc_path
  config_section = var.edgerc_section
}
