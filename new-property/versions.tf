terraform {
  required_providers {
    akamai = {
      source  = "akamai/akamai"
      version = "~> 10.2"
    }
  }
  required_version = ">= 1.9.0"

  backend "local" {}
}