# Default Akamai provider
provider "akamai" {
  edgerc         = var.edgerc_path
  config_section = var.edgerc_section
}