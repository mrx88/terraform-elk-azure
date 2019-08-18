# Set up grafana node
# Terraform code based on documentation https://www.terraform.io/docs/providers/azurerm/r/virtual_machine.html

# Create Public ip for grafana dashboard
resource "azurerm_public_ip" "grafana" {
  name                         = "elk-stack-grafana-pip"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  allocation_method = "Dynamic"
}

# Network security group for limiting access to grafana public dashboard
resource "azurerm_network_security_group" "grafana" {
  name                = "elk-grafana"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  security_rule {
    name                       = "allowtcp"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "${var.nsgip}"
    destination_address_prefix = "*"
  }
}

# Create network interface, attach public ip that we have created
resource "azurerm_network_interface" "grafana" {
  name                = "weu-elk-grafana1"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  network_security_group_id = "${azurerm_network_security_group.grafana.id}"

  ip_configuration {
    name                          = "weu-elk-grafana1"
    subnet_id                     = "${azurerm_subnet.network.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.grafana.id}"

  }
}

# Create VM
resource "azurerm_virtual_machine" "grafana" {
  name                  = "weu-elk-grafana1"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  network_interface_ids = ["${azurerm_network_interface.grafana.id}"]
  vm_size               = "Standard_A2_v2"
  delete_os_disk_on_termination = true
  depends_on            = ["azurerm_virtual_machine.jumpbox"]
# Upload Chef cookbook/recipes
  provisioner "file" {
    source      = "chef"
    destination = "/tmp/"

    connection {
      type     = "ssh"
      user     = "${var.ssh_user}"
      host = "weu-elk-grafana1"
      private_key = "${file("${var.ssh_privkey_location}")}"
      agent    = false
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
    name              = "weu-elk-grafana1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

   os_profile {
     computer_name  = "weu-elk-grafana1"
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

# Install chef-solo, start chef bootstrap
resource "azurerm_virtual_machine_extension" "grafana" {
  name                 = "weu-elk-grafana1"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  virtual_machine_name = "weu-elk-grafana1"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  depends_on           = ["azurerm_virtual_machine.grafana"]


  settings = <<SETTINGS
    {
        "commandToExecute": "curl -L https://www.opscode.com/chef/install.sh | sudo bash; chef-solo --chef-license accept-silent -c /tmp/chef/solo.rb -o elk-stack::grafana,elk-stack::monitoring"
    }
SETTINGS
}

  data "azurerm_public_ip" "grafana" {
  name                = "${azurerm_public_ip.grafana.name}"
  resource_group_name = "${azurerm_virtual_machine.grafana.resource_group_name}"
}

output "grafana_public_ip_address" {
  value = "${data.azurerm_public_ip.grafana.ip_address}"
}
