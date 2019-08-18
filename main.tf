# NOTE: created based on Terraform documentation
# https://www.terraform.io/docs/providers/azurerm/index.html
# Subscription and app details for accessing

provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
}


# Create a resource group
resource "azurerm_resource_group" "main" {
  name     = "elk-stack"
  location = "West Europe"
}

resource "azurerm_virtual_network" "network" {
  name                = "elk-stack"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
}

resource "azurerm_subnet" "network" {
  name                 = "elk-subnet"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  virtual_network_name = "${azurerm_virtual_network.network.name}"
  address_prefix       = "10.0.2.0/24"
}
