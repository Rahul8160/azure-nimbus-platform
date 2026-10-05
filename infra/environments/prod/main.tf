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


# Who is running Terraform: gives us the tenant ID and your object ID
data "azurerm_client_config" "current" {}

module "private_dns" {
  source = "../../modules/private_dns"

  resource_group_name = module.resource_groups.names["hub"]
  zones               = var.private_dns_zones
  vnet_links          = module.network.vnet_ids # link every zone to hub and spoke
  tags                = local.common_tags
}

module "acr" {
  source = "../../modules/acr"

  registries = {
    for k, v in var.container_registries : k => merge(v, {
      resource_group_name = module.resource_groups.names[v.resource_group_key]
      location            = module.resource_groups.locations[v.resource_group_key]
    })
  }
  tags = local.common_tags
}

module "key_vault" {
  source = "../../modules/key_vault"

  tenant_id = data.azurerm_client_config.current.tenant_id
  vaults = {
    for k, v in var.key_vaults : k => merge(v, {
      resource_group_name = module.resource_groups.names[v.resource_group_key]
      location            = module.resource_groups.locations[v.resource_group_key]
      allowed_ip_ranges   = var.admin_ip_ranges
      admin_object_ids    = [data.azurerm_client_config.current.object_id]
    })
  }
  tags = local.common_tags
}

locals {
  # Everything a private endpoint can point at, by "<type>/<key>".
  # Step 3b adds SQL and Cosmos DB here.
  private_endpoint_targets = merge(
    { for k, id in module.key_vault.ids : "keyvault/${k}" => id },
  )
}

module "private_endpoints" {
  source = "../../modules/private_endpoint"

  private_endpoints = {
    for k, v in var.private_endpoints : k => {
      resource_group_name  = module.resource_groups.names[v.resource_group_key]
      location             = module.resource_groups.locations[v.resource_group_key]
      subnet_id            = module.network.subnet_ids[v.subnet_key]
      resource_id          = local.private_endpoint_targets[v.target]
      subresource_names    = v.subresource_names
      private_dns_zone_ids = [module.private_dns.zone_ids[v.dns_zone_key]]
    }
  }
  tags = local.common_tags
}