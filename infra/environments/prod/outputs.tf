output "resource_group_names" {
  value = module.resource_groups.names
}

output "vnet_ids" {
  value = module.network.vnet_ids
}

output "subnet_ids" {
  value = module.network.subnet_ids
}


output "policy_assignment_ids" {
  value = module.policy.assignment_ids
}