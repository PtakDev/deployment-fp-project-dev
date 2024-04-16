# 1. Create resource group in which all resources for the project will be deployed.
resource "azurerm_resource_group" "rsg" {
  name     = local.rsg_name
  location = var.location

  tags = {
    environment = "staging"
  }
}

# 2. Create Azure Key Vault in which all project secters will be stored.
resource "azurerm_key_vault" "akv" {
  // COMMON RESOURCES CONFIG
  name                = local.akv_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rsg.name
  tenant_id           = var.tenant_id
  // AKV CONFIGURATION
  enabled_for_disk_encryption = var.azure_key_vault_config.enabled_for_disk_encryption
  soft_delete_retention_days  = var.azure_key_vault_config.soft_delete_retention_days
  purge_protection_enabled    = var.azure_key_vault_config.purge_protection_enabled
  sku_name                    = var.azure_key_vault_config.sku_name
  // ACCESS POLICY
  access_policy {
    tenant_id = var.tenant_id
    object_id = var.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
    ]

    storage_permissions = [
      "Get",
    ]
  }
  // TAGGING
  tags = {
    environment = var.env_tag
  }
}

# 3. Creates Storage account resource used for project.
resource "azurerm_storage_account" "sta" {
  // COMMON
  name                = local.sta_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rsg.name
  // STA CONFIG
  account_tier                  = var.storage_account_config.account_tier
  account_replication_type      = var.storage_account_config.account_replication_type
  access_tier                   = var.storage_account_config.access_tier
  account_kind                  = var.storage_account_config.account_kind
  public_network_access_enabled = var.storage_account_config.public_network_access_enabled
  // TAGGING
  tags = {
    environment = var.env_tag
  }
}

# 4. Log Analytics Workspace resource used for project.
resource "azurerm_log_analytics_workspace" "lwk" {
  // COMMON
  name                = local.lwk_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rsg.name
  // LWK CONFIG
  sku               = var.log_analytics_workspace_config.sku
  retention_in_days = var.log_analytics_workspace_config.retention_in_days
  // TAGGING
  tags = {
    environment = var.env_tag
  }
}

# 5. Virtual Network resource used for project.
resource "azurerm_virtual_network" "vnt" {
  name                = local.vnt_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rsg.name
  // VNT CONFIG
  address_space = var.vnt_address_space
  // TAGGING
  tags = {
    environment = var.env_tag
  }
}

# 6. Subnet exposed to internet and all related resources
resource "azurerm_subnet" "web-snt" {
  depends_on = [azurerm_virtual_network.vnt]
  // COMMON
  name                = join("", [local.vnt_name, "-snt", var.web_subnet_config.snt_number])
  resource_group_name = azurerm_resource_group.rsg.name
  // SNT CONFIG
  virtual_network_name = azurerm_virtual_network.vnt.name
  address_prefixes     = var.web_subnet_config.snt_address_prefixes
}

resource "azurerm_network_security_group" "web-nsg" {
  depends_on          = [azurerm_subnet.web-snt]
  name                = join("", [local.vnt_name, "-nsg", var.web_subnet_config.snt_number])
  location            = var.location
  resource_group_name = azurerm_resource_group.rsg.name

  security_rule {
    name                       = "allow_https"
    priority                   = 2990
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_ranges          = [443]
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  // TAGGING
  tags = {
    environment = var.env_tag
  }
}

resource "azurerm_subnet_network_security_group_association" "web-nsg-association" {
  depends_on                = [azurerm_network_security_group.web-nsg]
  subnet_id                 = azurerm_subnet.web-snt.id
  network_security_group_id = azurerm_network_security_group.web-nsg.id
}

resource "azurerm_route_table" "web-rtb" {
  depends_on          = [azurerm_subnet.web-snt]
  name                = join("", [local.vnt_name, "-rtb", var.web_subnet_config.snt_number])
  location            = var.location
  resource_group_name = azurerm_resource_group.rsg.name
  // TAGGING
  tags = {
    environment = var.env_tag
  }
}

resource "azurerm_subnet_route_table_association" "web-rtb-association" {
  depends_on     = [azurerm_route_table.web-rtb]
  subnet_id      = azurerm_subnet.web-snt.id
  route_table_id = azurerm_route_table.web-rtb.id
}

# 7. Public IP
resource "azurerm_public_ip" "web-pip" {
  name                = join("", [local.vm_name, "-pip01"])
  resource_group_name = azurerm_resource_group.rsg.name
  location            = var.location
  allocation_method   = var.public_ip_config.allocation_method
  // TAGGING
  tags = {
    environment = var.env_tag
  }
}

# 8. Network Interface
resource "azurerm_network_interface" "web-nic" {
  depends_on          = [azurerm_public_ip.web-pip]
  name                = join("", [local.vm_name, "-nic01"])
  location            = var.location
  resource_group_name = azurerm_resource_group.rsg.name

  ip_configuration {
    name                          = "External"
    subnet_id                     = azurerm_subnet.web-snt.id
    private_ip_address_allocation = "Static"
    public_ip_address_id          = azurerm_public_ip.web-pip.id
    private_ip_address            = cidrhost(var.web_subnet_config.snt_address_prefixes[0], 5)
  }
}


#### Internal comunication infraestructure
# 6. Subnet exposed to internet and all related resources
resource "azurerm_subnet" "int-snt" {
  depends_on = [azurerm_virtual_network.vnt]
  // COMMON
  name                = join("", [local.vnt_name, "-snt", var.int_subnet_config.snt_number])
  resource_group_name = azurerm_resource_group.rsg.name
  // SNT CONFIG
  virtual_network_name = azurerm_virtual_network.vnt.name
  address_prefixes     = var.int_subnet_config.snt_address_prefixes
}

resource "azurerm_network_security_group" "int-nsg" {
  depends_on          = [azurerm_subnet.int-snt]
  name                = join("", [local.vnt_name, "-nsg", var.int_subnet_config.snt_number])
  location            = var.location
  resource_group_name = azurerm_resource_group.rsg.name

  security_rule {
    name                       = "allow_ftp_ssh"
    priority                   = 2990
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_ranges          = [21, 22]
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  // TAGGING
  tags = {
    environment = var.env_tag
  }
}

resource "azurerm_subnet_network_security_group_association" "int-nsg-association" {
  depends_on                = [azurerm_network_security_group.int-nsg]
  subnet_id                 = azurerm_subnet.int-snt.id
  network_security_group_id = azurerm_network_security_group.int-nsg.id
}

resource "azurerm_route_table" "int-rtb" {
  depends_on          = [azurerm_subnet.int-snt]
  name                = join("", [local.vnt_name, "-rtb", var.int_subnet_config.snt_number])
  location            = var.location
  resource_group_name = azurerm_resource_group.rsg.name
  // TAGGING
  tags = {
    environment = var.env_tag
  }
}

resource "azurerm_subnet_route_table_association" "int-rtb-association" {
  depends_on     = [azurerm_route_table.int-rtb]
  subnet_id      = azurerm_subnet.int-snt.id
  route_table_id = azurerm_route_table.int-rtb.id
}

# 7. Public IP
resource "azurerm_public_ip" "int-pip" {
  name                = join("", [local.vm_name, "-pip02"])
  resource_group_name = azurerm_resource_group.rsg.name
  location            = var.location
  allocation_method   = var.public_ip_config.allocation_method
  // TAGGING
  tags = {
    environment = var.env_tag
  }
}

# 8. Network Interface
resource "azurerm_network_interface" "int-nic" {
  depends_on          = [azurerm_public_ip.int-pip]
  name                = join("", [local.vm_name, "-nic02"])
  location            = var.location
  resource_group_name = azurerm_resource_group.rsg.name

  ip_configuration {
    name                          = "External"
    subnet_id                     = azurerm_subnet.int-snt.id
    private_ip_address_allocation = "Static"
    public_ip_address_id          = azurerm_public_ip.int-pip.id
    private_ip_address            = cidrhost(var.int_subnet_config.snt_address_prefixes[0], 5)
  }
}


resource "azurerm_linux_virtual_machine" "vm-linux" {
  depends_on          = [
    azurerm_network_interface.web-nic, 
    azurerm_network_interface.int-nic
  ]

  name                = local.vm_name
  resource_group_name = azurerm_resource_group.rsg.name
  location            = var.location
  size                = var.vm_size

  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.web-nic.id,
    azurerm_network_interface.int-nic.id,
  ]

  # admin_ssh_key {
  #   username   = var.admin_username
  #   public_key = file("~/.ssh/id_rsa.pub")
  # }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

#   identity {
#     type = "SystemAssigned"
#   }

  custom_data = filebase64("./vm_scripts/default_config.sh")
}