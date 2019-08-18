# Set up Logstash node
# Terraform code based on documentation https://www.terraform.io/docs/providers/azurerm/r/virtual_machine.html
resource "azurerm_network_interface" "logstash" {
  name                = "weu-elk-logstash1"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  ip_configuration {
    name                          = "weu-elk-logstash1"
    subnet_id                     = "${azurerm_subnet.network.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_virtual_machine" "logstash" {
  name                  = "weu-elk-logstash1"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  network_interface_ids = ["${azurerm_network_interface.logstash.id}"]
  vm_size               = "Standard_A2_v2"
  delete_os_disk_on_termination = true
  depends_on            = ["azurerm_virtual_machine.jumpbox", "azurerm_virtual_machine.elastic"]

    provisioner "file" {
      source      = "chef"
      destination = "/tmp/"

      connection {
        type     = "ssh"
        user     = "${var.ssh_user}"
        host = "weu-elk-logstash1"
        private_key = "${file("${var.ssh_privkey_location}")}"
        agent    = false
      #  key_file = "${file("~/.ssh/id_rsa")}"
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
    name              = "weu-elk-logstash1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

   os_profile {
     computer_name  = "weu-elk-logstash1"
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

resource "azurerm_virtual_machine_extension" "logstash" {
  name                 = "weu-elk-logstash1"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  virtual_machine_name = "weu-elk-logstash1"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  depends_on           = ["azurerm_virtual_machine.logstash"]

  settings = <<SETTINGS
    {
        "commandToExecute": "curl -L https://www.opscode.com/chef/install.sh | sudo bash; chef-solo --chef-license accept-silent -c /tmp/chef/solo.rb -o elk-stack::repo-setup,elk-stack::logstash,elk-stack::monitoring"
    }
SETTINGS
}
