# -------------------------------------------------
# TODO: Add module calls sourced from terraform-templates-modules.
#
# Example pattern:
#
# data "akamai_contract" "contract" {
#   group_name = var.group_name
# }
#
# module "my-module" {
#   source = "git::ssh://git@github.com/akamai/terraform-templates-modules.git//{product}/my-module?ref=vX.Y.Z"
#
#   contract_id = trimprefix(data.akamai_contract.contract.id, "ctr_")
#   group_id    = trimprefix(data.akamai_contract.contract.group_id, "grp_")
#   environment = var.environment
#   # ... product-specific variables
# }
# -------------------------------------------------
