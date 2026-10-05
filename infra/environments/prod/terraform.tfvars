owner = "rahul"

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
        address_prefixes                = ["10.0.1.0/27"]
        create_nsg                      = true
        default_outbound_access_enabled = true # lab: jumpbox downloads its tools; production uses NAT Gateway or the firewall
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


# ---------- Governance: Azure Policy ----------
policy_assignments = {
  allowed-locations = {
    display_name         = "Nimbus: allowed locations (Central and South India)"
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
    parameters = {
      listOfAllowedLocations = ["centralindia", "southindia"]
    }
  }

  allowed-vm-sizes = {
    display_name         = "Nimbus: allowed VM sizes (cost guardrail)"
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/cccc23c7-8427-4f53-ad12-b6a63eb452b3"
    parameters = {
        listOfAllowedSKUs = ["Standard_B1s", "Standard_B2s", "Standard_B2ms", "Standard_B2s_v2", "Standard_B2ls_v2"]
    }
  }

  require-rg-tags = {
    display_name          = "Nimbus: resource groups must have project, owner, environment tags"
    custom_definition_key = "require-rg-tags"
  }
}

# ---------- Cost: budget alerts ----------
alert_emails = ["rahulraval870@gmail.com"] # replace with your real email

budgets = {
  budget-nimbus-monthly = {
    amount     = 8000 # in your billing currency (INR for an Indian trial account)
    start_date = "2026-10-01T00:00:00Z"
  }
}


# ---------- Access ----------
admin_ip_ranges = ["152.59.0.0/16"] # your home public IP; /32 means exactly one address

# ---------- Private DNS (central, in the hub) ----------
private_dns_zones = {
  keyvault = "privatelink.vaultcore.azure.net"
  sql      = "privatelink.database.windows.net"
  cosmos   = "privatelink.documents.azure.com"
}

# ---------- Shared services ----------
container_registries = {
  main = {
    name               = "acrnimbusf78654" # globally unique, letters and numbers only
    resource_group_key = "shared"
    sku                = "Basic"
  }
}

key_vaults = {
  main = {
    name               = "kv-nimbus-f786969" # globally unique, 3-24 characters
    resource_group_key = "shared"
  }
}

# ---------- Private endpoints (all in the spoke's snet-pe) ----------
private_endpoints = {
  kv-main = {
    resource_group_key = "workload"
    subnet_key         = "spoke/snet-pe"
    target             = "keyvault/main"
    subresource_names  = ["vault"]
    dns_zone_key       = "keyvault"
  }
  sql-main = {
    resource_group_key = "workload"
    subnet_key         = "spoke/snet-pe"
    target             = "sql/main"
    subresource_names  = ["sqlServer"]
    dns_zone_key       = "sql"
  }
  cosmos-main = {
    resource_group_key = "workload"
    subnet_key         = "spoke/snet-pe"
    target             = "cosmos/main"
    subresource_names  = ["Sql"] # "Sql" = the NoSQL API endpoint of Cosmos DB
    dns_zone_key       = "cosmos"
  }
}


# ---------- Data ----------
sql_servers = {
  main = {
    name               = "sql-nimbus-f786969" # globally unique, lowercase
    resource_group_key = "workload"
    entra_admin_login  = "vm-jumpbox-nimbus-cin"
    databases = {
      ordersdb = {
        sku_name    = "Basic"
        max_size_gb = 2
      }
    }
  }
}

cosmos_accounts = {
  main = {
    name               = "cosmos-nimbus-f786969" # globally unique, lowercase
    resource_group_key = "workload"
    databases = {
      nimbus = {
        containers = {
          inventory = {
            partition_key_path = "/id"
            throughput         = 400
          }
        }
      }
    }
  }
}

# ---------- Messaging ----------
servicebus_namespaces = {
  main = {
    name               = "sb-nimbus-f786969" # globally unique
    resource_group_key = "workload"
    sku                = "Basic"
    queues = {
      order-placed = {
        max_delivery_count  = 3
        lock_duration       = "PT1M"
        default_message_ttl = "PT1H"
      }
    }
  }
}



# ---------- Kubernetes ----------
aks_clusters = {
  main = {
    name                = "aks-nimbus-cin"
    dns_prefix          = "aks-nimbus"
    node_resource_group = "rg-nimbus-aks-nodes-cin" # AKS creates and manages this group
    resource_group_key  = "workload"
    subnet_key          = "spoke/snet-aks"
    acr_key             = "main"
    node_vm_size        = "Standard_B2s_v2"
    node_count          = 1
    dns_link_vnet_keys  = ["hub"] # jumpbox and VPN live in the hub
  }
}



# ---------- Workload identities (one per microservice, least privilege) ----------
workload_identities = {
  orders = {
    resource_group_key = "workload"
    aks_key            = "main"
    namespace          = "nimbus"
    service_account    = "orders-service"
    azure_roles = {
      servicebus-send = {
        target = "servicebus_queue/main/order-placed"
        role   = "Azure Service Bus Data Sender"
      }
    }
    # SQL access is granted inside the database in Step 3
  }

  inventory = {
    resource_group_key = "workload"
    aks_key            = "main"
    namespace          = "nimbus"
    service_account    = "inventory-service"
    azure_roles = {
      servicebus-receive = {
        target = "servicebus_queue/main/order-placed"
        role   = "Azure Service Bus Data Receiver"
      }
    }
    cosmos_roles = {
      inventory-data = {
        account         = "main"
        path            = "/dbs/nimbus/colls/inventory"          # only this container
        role_definition = "00000000-0000-0000-0000-000000000002" # Cosmos DB Built-in Data Contributor
      }
    }
  }
}


# ---------- Admin access ----------
bastions = {
  hub = {
    name               = "bas-nimbus-hub-cin"
    resource_group_key = "hub"
    vnet_key           = "hub"
    sku                = "Developer"
  }
}

virtual_machines = {
  jumpbox = {
    name                = "vm-jumpbox-nimbus-cin"
    resource_group_key  = "hub"
    subnet_key          = "hub/snet-jumpbox"
    size                = "Standard_B2ls_v2"
    ssh_public_key_path = "~/.ssh/nimbus_jumpbox.pub"
    cloud_init_file     = "cloud-init/jumpbox.yaml"
  }
}