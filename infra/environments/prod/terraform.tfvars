owner = "dhruvansh"

# ---------- Resource groups ----------
resource_groups = {
  hub = {
    name     = "rg-nimbus-hub-cin"
    location = "centralindia"
    tags     = { layer = "network" }
  }
  workload = {
    name     = "rg-nimbus-workload-cin"
    location = "centralindia"
    tags     = { layer = "workload" }
  }
  shared = {
    name     = "rg-nimbus-shared-cin"
    location = "centralindia"
    tags     = { layer = "shared" }
  }
}

# ---------- Networks ----------
vnets = {
  hub = {
    name               = "vnet-nimbus-hub-cin"
    resource_group_key = "hub"
    address_space      = ["10.0.0.0/22"]

    subnets = {
      # Names below are fixed by Azure. No custom NSG allowed.
      AzureFirewallSubnet           = { address_prefixes = ["10.0.0.0/26"] }
      AzureFirewallManagementSubnet = { address_prefixes = ["10.0.0.64/26"] }
      GatewaySubnet                 = { address_prefixes = ["10.0.0.128/27"] }

      snet-jumpbox = {
        address_prefixes = ["10.0.1.0/27"]
        create_nsg       = true
        nsg_rules = {
          # Bastion Developer connects from Azure's platform IP
          allow-bastion-ssh = {
            priority               = 100
            direction              = "Inbound"
            access                 = "Allow"
            protocol               = "Tcp"
            destination_port_range = "22"
            source_address_prefix  = "168.63.129.16"
          }
        }
      }
    }
  }

  spoke = {
    name               = "vnet-nimbus-spoke-cin"
    resource_group_key = "workload"
    address_space      = ["10.1.0.0/22"]

    subnets = {
      snet-aks = {
        address_prefixes = ["10.1.0.0/24"]
        create_nsg       = true
        nsg_rules = {
          # Users reach the ingress on HTTP/HTTPS
          allow-web-inbound = {
            priority                = 100
            direction               = "Inbound"
            access                  = "Allow"
            protocol                = "Tcp"
            destination_port_ranges = ["80", "443"]
            source_address_prefix   = "Internet"
          }
        }
      }

      snet-pe = {
        address_prefixes                  = ["10.1.1.0/27"]
        private_endpoint_network_policies = "Enabled" # lets the NSG apply to private endpoints
        create_nsg                        = true
        nsg_rules = {
          # Only AKS nodes, the jumpbox and VPN clients may reach the databases / Key Vault
          allow-trusted-inbound = {
            priority                = 100
            direction               = "Inbound"
            access                  = "Allow"
            protocol                = "Tcp"
            destination_port_ranges = ["443", "1433"]
            source_address_prefixes = ["10.1.0.0/24", "10.0.1.0/27", "172.16.0.0/24"]
          }
          deny-all-inbound = {
            priority               = 4096
            direction              = "Inbound"
            access                 = "Deny"
            protocol               = "*"
            destination_port_range = "*"
            source_address_prefix  = "*"
          }
        }
      }
    }
  }
}

# ---------- Peering ----------
peerings = {
  hub-spoke = {
    hub_key         = "hub"
    spoke_key       = "spoke"
    use_hub_gateway = false # set to true on Day 3 after the VPN gateway exists
  }
}