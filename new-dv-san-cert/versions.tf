terraform {
  required_providers {
    akamai = {
      source  = "akamai/akamai"
      version = "~> 9.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.6"
    }

  }
  required_version = ">= 1.9.0"

  backend "local" {}
}