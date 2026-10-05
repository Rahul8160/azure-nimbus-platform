locals {
  # One role assignment per (cluster, admin). Key example: "main/<object-id>"
  cluster_admins = merge([
    for cluster_key, cluster in var.clusters : {
      for object_id in cluster.admin_object_ids :
      "${cluster_key}/${object_id}" => {
        cluster_key = cluster_key
        object_id   = object_id
      }
    }
  ]...)

  # One DNS link per (cluster, extra VNet). Key example: "main/hub"
  api_dns_links = merge([
    for cluster_key, cluster in var.clusters : {
      for vnet_key, vnet_id in cluster.dns_link_vnet_ids :
      "${cluster_key}/${vnet_key}" => {
        cluster_key = cluster_key
        vnet_key    = vnet_key
        vnet_id     = vnet_id
      }
    }
  ]...)
}

# ---------- 1. Control-plane identity, created BEFORE the cluster ----------
resource "azurerm_user_assigned_identity" "control_plane" {
  for_each = var.clusters

  name                = "id-${each.value.name}"
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  tags                = var.tags
}

# AKS needs to manage networking in our subnet (attach load balancers, NICs)
resource "azurerm_role_assignment" "network_contributor" {
  for_each = var.clusters

  scope                = each.value.subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.control_plane[each.key].principal_id
}

# ---------- 2. The cluster ----------
resource "azurerm_kubernetes_cluster" "cluster" {
  for_each = var.clusters

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  dns_prefix          = each.value.dns_prefix
  node_resource_group = each.value.node_resource_group
  kubernetes_version  = each.value.kubernetes_version
  sku_tier            = "Free"
  tags                = var.tags

  # Private API server; AKS manages its private DNS zone ("System")
  private_cluster_enabled = true
  private_dns_zone_id     = "System"

  # Identity and access
  local_account_disabled            = true # no shared admin kubeconfig
  role_based_access_control_enabled = true
  oidc_issuer_enabled               = true # required for workload identity
  workload_identity_enabled         = true

  azure_active_directory_role_based_access_control {
    tenant_id          = each.value.tenant_id
    azure_rbac_enabled = true # Kubernetes permissions come from Azure role assignments
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.control_plane[each.key].id]
  }

  default_node_pool {
    name                        = "system"
    vm_size                     = each.value.node_vm_size
    node_count                  = each.value.node_count
    vnet_subnet_id              = each.value.subnet_id
    os_disk_size_gb             = each.value.node_os_disk_gb
    temporary_name_for_rotation = "systemtmp" # lets Terraform change node settings without destroying the cluster

    upgrade_settings {
      max_surge = "10%"
    }
  }
  # How node pools are managed: Manual = we define them ourselves (default_node_pool above)
  node_provisioning_profile {
    mode = "Manual"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay" # pods get IPs from pod_cidr, not from the subnet
    network_policy      = "azure"   # enables Kubernetes NetworkPolicy (used in Step 4)
    pod_cidr            = each.value.pod_cidr
    service_cidr        = each.value.service_cidr
    dns_service_ip      = each.value.dns_service_ip
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer" # Step 5 switches this path through the firewall
  }

  # Lets pods mount Key Vault secrets as files
  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  # The identity must have its subnet permission before AKS tries to use the subnet
  depends_on = [azurerm_role_assignment.network_contributor]
}

# ---------- 3. Nodes may pull images from ACR ----------
resource "azurerm_role_assignment" "acr_pull" {
  for_each = var.clusters

  scope                = each.value.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.cluster[each.key].kubelet_identity[0].object_id
}

# ---------- 4. You may administer the cluster with kubectl ----------
resource "azurerm_role_assignment" "cluster_admin" {
  for_each = local.cluster_admins

  scope                = azurerm_kubernetes_cluster.cluster[each.value.cluster_key].id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = each.value.object_id
}


# ---------- 5. Let other VNets (e.g. the hub) resolve the private API server ----------
# AKS's private FQDN looks like: <prefix>-<hash>.<guid>.privatelink.<region>.azmk8s.io
# The private DNS zone is everything after the first dot, inside the AKS node resource group.
resource "azurerm_private_dns_zone_virtual_network_link" "api_server" {
  for_each = local.api_dns_links

  name = "link-${each.value.vnet_key}"
  private_dns_zone_id = format(
    "%s/providers/Microsoft.Network/privateDnsZones/%s",
    azurerm_kubernetes_cluster.cluster[each.value.cluster_key].node_resource_group_id,
    join(".", slice(
      split(".", azurerm_kubernetes_cluster.cluster[each.value.cluster_key].private_fqdn),
      1,
      length(split(".", azurerm_kubernetes_cluster.cluster[each.value.cluster_key].private_fqdn))
    ))
  )
  virtual_network_id   = each.value.vnet_id
  registration_enabled = false
}



# ---------- 6. Admins may download cluster credentials (az aks get-credentials) ----------
resource "azurerm_role_assignment" "cluster_user" {
  for_each = local.cluster_admins

  scope                = azurerm_kubernetes_cluster.cluster[each.value.cluster_key].id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = each.value.object_id
}