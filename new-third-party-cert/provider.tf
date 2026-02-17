# Read Akamai credentials from .edgerc file
provider "akamai" {
  edgerc         = var.edgerc_path
  config_section = var.edgerc_section
}