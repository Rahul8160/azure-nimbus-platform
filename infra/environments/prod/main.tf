locals {
  common_tags = {
    project     = var.project
    environment = var.environment
    owner       = var.owner
    managed-by  = "terraform"
  }
}

module "resource_groups" {
  source = "../../modules/resource_group"

  resource_groups = var.resource_groups
  common_tags     = local.common_tags
}