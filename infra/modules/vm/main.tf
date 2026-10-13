resource "azurerm_network_interface" "nic" {
  for_each = var.vms

  name                = "nic-${each.value.name}"
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  tags                = var.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = each.value.subnet_id
    private_ip_address_allocation = "Dynamic" # no public IP at all
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  for_each = var.vms

  name                            = each.value.name
  resource_group_name             = each.value.resource_group_name
  location                        = each.value.location
  size                            = each.value.size
  admin_username                  = each.value.admin_username
  network_interface_ids           = [azurerm_network_interface.nic[each.key].id]
  disable_password_authentication = true # SSH keys only
  custom_data                     = each.value.custom_data != null ? base64encode(each.value.custom_data) : null
  tags                            = var.tags

  admin_ssh_key {
    username   = each.value.admin_username
    public_key = each.value.ssh_public_key
  }


  # The VM's own Entra ID identity (used for az login --identity)
  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = each.value.os_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

# Stop paying for the VM overnight
resource "azurerm_dev_test_global_vm_shutdown_schedule" "auto_shutdown" {
  for_each = var.vms

  virtual_machine_id    = azurerm_linux_virtual_machine.vm[each.key].id
  location              = each.value.location
  enabled               = true
  daily_recurrence_time = each.value.auto_shutdown_time
  timezone              = each.value.auto_shutdown_timezone

  notification_settings {
    enabled = false
  }
}