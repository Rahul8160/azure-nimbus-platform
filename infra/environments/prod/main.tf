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

module "network" {
  source = "../../modules/network"

  # tfvars says which resource group each VNet belongs to (resource_group_key).
  # Here we swap that key for the real name and location from the resource_group module.
  # This also tells Terraform: create resource groups before VNets.
  vnets = {
    for k, v in var.vnets : k => merge(v, {
      resource_group_name = module.resource_groups.names[v.resource_group_key]
      location            = module.resource_groups.locations[v.resource_group_key]
    })
  }

  peerings = var.peerings
  tags     = local.common_tags
}


module "policy" {
  source = "../../modules/policy"

  # tfvars can't read files, so custom policy JSON is loaded here
  custom_definitions = {
    require-rg-tags = {
      display_name = "Nimbus: resource groups must have required tags"
      description  = "Audits resource groups missing any of the listed tags"
      mode         = "All"
      policy_rule  = file("${path.module}/policies/require-tags.rules.json")
    }
  }

  assignments = var.policy_assignments
}

module "budget" {
  source = "../../modules/budget"

  budgets        = var.budgets
  contact_emails = var.alert_emails
}