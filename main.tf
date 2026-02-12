# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  location = var.location
  name     = var.project_name
  tags = var.common_tags
}

resource "azurerm_virtual_network" "main" {
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  name                = "${var.environment}-network"
  resource_group_name = azurerm_resource_group.main.name
  tags = var.common_tags
}

resource "azurerm_network_security_group" "main" {
  location            = azurerm_resource_group.main.location
  name                = "acceptanceTestSecurityGroup1"
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    protocol                   = "Tcp"
    source_port_range          = "*"
    access                     = "Allow"
    destination_port_range     = "22"
    source_address_prefix      = var.ip_address
    destination_address_prefix = "*"
  }

  tags = var.common_tags
}

resource "azurerm_subnet_network_security_group_association" "main" {
  network_security_group_id = azurerm_network_security_group.main.id
  subnet_id                 = azurerm_subnet.internal.id
}

resource "azurerm_subnet" "internal" {
  address_prefixes     = ["10.0.2.0/24"]
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
}

resource "azurerm_network_interface" "main" {
  name                = "${var.environment}-interface"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.internal.id
    public_ip_address_id          = azurerm_public_ip.external.id
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  admin_username        = "adminuser"
  location              = azurerm_resource_group.main.location
  name                  = "${var.environment}-vm"
  network_interface_ids = [azurerm_network_interface.main.id]
  resource_group_name   = azurerm_resource_group.main.name
  size                  = var.virtual_machine_size
  zone                  = "2"

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/azure.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  tags = var.common_tags
}

resource "azurerm_public_ip" "external" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.main.location
  name                = "external"
  resource_group_name = azurerm_resource_group.main.name
}
