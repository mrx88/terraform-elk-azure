# Set up JB for accessing ELK stack VMs
# Terraform code based on https://www.terraform.io/docs/providers/azurerm/r/virtual_machine.html

# Create NSG for limiting access to JB

resource "azurerm_network_security_group" "jumpbox" {
  name                = "elk-jumpbox"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  security_rule {
    name                       = "allowtcp"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${var.nsgip}"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "jumpbox" {
  name                = "weu-elk-jumpbox1"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  network_security_group_id = "${azurerm_network_security_group.jumpbox.id}"


  ip_configuration {
    name                          = "weu-elk-jumpbox1"
    subnet_id                     = "${azurerm_subnet.network.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.jumpbox.id}"

  }
}

resource "azurerm_public_ip" "jumpbox" {
  name                         = "elk-stack-jb-pip"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  allocation_method   = "Static"
}

resource "azurerm_virtual_machine" "jumpbox" {
  name                  = "weu-elk-jumpbox1"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  network_interface_ids = ["${azurerm_network_interface.jumpbox.id}"]
  vm_size               = "Standard_A0"
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "weu-elk-jumpbox1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

   os_profile {
     computer_name  = "weu-elk-jumpbox1"
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
  data "azurerm_public_ip" "jumpbox" {
  name                = "${azurerm_public_ip.jumpbox.name}"
  resource_group_name = "${azurerm_virtual_machine.jumpbox.resource_group_name}"
}

output "jumpbox_public_ip_address" {
  value = "${data.azurerm_public_ip.jumpbox.ip_address}"
}
