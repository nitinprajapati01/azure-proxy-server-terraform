# Configure the Microsoft Azure Provider
provider "azurerm" {
    subscription_id = var.AZURE_SUBSCRIPTION_ID
    # client_id       = var.AZURE_CLIENT_ID
    # client_secret   = var.AZURE_CLIENT_SECRET
    tenant_id       = var.AZURE_TENANT_ID
    features {
        resource_group {
          prevent_deletion_if_contains_resources = false
        }
    }
}

resource "azurerm_resource_group" "myterraformgroup" {
    name     = "proxyResourceGroup"
    location = var.AZURE_DEFAULT_REGION

    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = var.AZURE_DEFAULT_REGION
    resource_group_name = azurerm_resource_group.myterraformgroup.name

    tags = {
        environment = "Terraform Demo"
    }
}


resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "mySubnet"
    resource_group_name  = azurerm_resource_group.myterraformgroup.name
    virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
    address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "myterraformpublicip" {
    count                        = var.AZURE_INSTANCES_COUNT
    name                         = "pip-${count.index}"
    location                     = var.AZURE_DEFAULT_REGION
    resource_group_name          = azurerm_resource_group.myterraformgroup.name
    allocation_method            = "Static"

    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = var.AZURE_DEFAULT_REGION
    resource_group_name = azurerm_resource_group.myterraformgroup.name

    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_network_security_rule" "outbound_internet_access" {
    name = "outbound_internet_access"
    priority = 100
    direction = "Outbound"
     access = "Allow"
    protocol = "*"
    source_port_range = "*"
    destination_port_range = "*"
    source_address_prefix = "*"
    destination_address_prefix = "*"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
    network_security_group_name = "${azurerm_network_security_group.myterraformnsg.name}"
}

resource "azurerm_network_security_rule" "incoming_proxy_traffic" {
    name = "incoming_proxy_traffic"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = var.PROXY_PORT
    source_address_prefix = "*"
    destination_address_prefix = "*"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
    network_security_group_name = "${azurerm_network_security_group.myterraformnsg.name}"
}

resource "azurerm_network_security_rule" "incoming_ssh" {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
    network_security_group_name = "${azurerm_network_security_group.myterraformnsg.name}"
}

resource "azurerm_network_interface" "nic" {
    count                       = var.AZURE_INSTANCES_COUNT
    name                        = "nic-${count.index}"
    location                    = var.AZURE_DEFAULT_REGION
    resource_group_name         = azurerm_resource_group.myterraformgroup.name
    # network_security_group_id   = azurerm_network_security_group.myterraformnsg.id

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.myterraformsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = element(concat(azurerm_public_ip.myterraformpublicip.*.id, tolist([""])), count.index)
    }

    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_virtual_machine" "myterraformvm" {
    count                 = var.AZURE_INSTANCES_COUNT
    name                  = "proxy-node-${count.index}"
    location              = var.AZURE_DEFAULT_REGION
    resource_group_name   = azurerm_resource_group.myterraformgroup.name
    network_interface_ids = ["${element(azurerm_network_interface.nic.*.id, count.index)}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "proxy-os-disk-${count.index}"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = var.AZURE_INSTANCE_USER_NAME
        admin_username = var.AZURE_INSTANCE_USER_NAME
        admin_password = var.AZURE_INSTANCE_PASSWORD
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

    tags = {
        environment = "Terraform Demo"
    }

    provisioner "file" {
        source      = "setup.sh"
        destination = "/home/${var.AZURE_INSTANCE_USER_NAME}/setup.sh"

          connection {
            type     = "ssh"
            user     = var.AZURE_INSTANCE_USER_NAME
            password = var.AZURE_INSTANCE_PASSWORD
            host     = azurerm_public_ip.myterraformpublicip[count.index].ip_address
        }
    }

    provisioner "remote-exec" {
        inline = [
        "chmod +x ./setup.sh",
        "sudo sed -i -e 's/\r$//' setup.sh",
        "sudo sh setup.sh ${var.AZURE_INSTANCE_USER_NAME} ${var.PROXY_TYPE} ${var.PROXY_PORT} ${var.PROXY_USER} ${var.PROXY_PASSWORD}",
        ]

        connection {
            type     = "ssh"
            user     = var.AZURE_INSTANCE_USER_NAME
            password = var.AZURE_INSTANCE_PASSWORD
            host     = azurerm_public_ip.myterraformpublicip[count.index].ip_address
        }
    }
}

output "public_ip_id" {
  description = "id of the public ip address provisoned."
  value       = "${azurerm_public_ip.myterraformpublicip.*.id}"
}

output "public_ip_address" {
  description = "The actual ip address allocated for the resource."
  value       = "${azurerm_public_ip.myterraformpublicip.*.ip_address}"
}
