terraform {
  required_providers {
    akamai = {
      source  = "akamai/akamai"
      version = "~> 10.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
  required_version = ">= 1.9.0"

  backend "local" {}
}
