# Set up elasticsearch nodes
# Terraform code based on documentation https://www.terraform.io/docs/providers/azurerm/r/virtual_machine.html
resource "azurerm_network_interface" "elastic" {
  name                = "weu-elk-elastic${count.index}"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  count               = 3
  ip_configuration {
    name                          = "weu-elk-elastic${count.index}"
    subnet_id                     = "${azurerm_subnet.network.id}"
    private_ip_address_allocation = "dynamic"
  }
}

# For better availability, create availability set
resource "azurerm_availability_set" "avset" {
  name                         = "weu-elk-elastic"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

# Create 3 VMs for elasticsearch nodes
resource "azurerm_virtual_machine" "elastic" {
  name                  = "weu-elk-elastic${count.index}"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  network_interface_ids = ["${element(azurerm_network_interface.elastic.*.id, count.index)}"]
  availability_set_id   = "${azurerm_availability_set.avset.id}"
  vm_size               = "Standard_A2_v2"
  delete_os_disk_on_termination = true
  count                 = 3
  depends_on            = ["azurerm_virtual_machine.jumpbox"]

# Upload Chef recipes
  provisioner "file" {
    source      = "chef"
    destination = "/tmp/"

    connection {
      type     = "ssh"
      user     = "${var.ssh_user}"
      host = "weu-elk-elastic${count.index}"
      private_key = "${file("${var.ssh_privkey_location}")}"
      agent    = false
    # Using Jumpbox for accessing VMs as I don't have VPN solution for these networks in test subscription
      bastion_user     = "${var.ssh_user}"
      bastion_host     = "${data.azurerm_public_ip.jumpbox.ip_address}"
      bastion_private_key = "${file("${var.ssh_privkey_location}")}"
      timeout = "6m"
    }
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "weu-elk-elastic${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

   os_profile {
     computer_name  = "weu-elk-elastic${count.index}"
     admin_username = "${var.ssh_user}"
   }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.ssh_user}/.ssh/authorized_keys"
      key_data = "${file("${var.ssh_pubkey_location}")}"
    }
  }

  tags = {
    environment = "development"
  }
}

# Using azure custom script extension, same can be achieved using terraform's
# remote-exec provisioner. Bootstrap node(s) with Chef.
resource "azurerm_virtual_machine_extension" "elastic" {
  name                 = "weu-elk-elastic${count.index}"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  virtual_machine_name = "weu-elk-elastic${count.index}"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  count                = 3
  depends_on           = ["azurerm_virtual_machine.elastic"]

  settings = <<SETTINGS
    {
        "commandToExecute": "curl -L https://www.opscode.com/chef/install.sh | sudo bash; chef-solo --chef-license accept-silent -c /tmp/chef/solo.rb -o elk-stack::repo-setup,elk-stack::elastic,elk-stack::monitoring"
    }
SETTINGS
}
