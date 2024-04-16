azure_key_vault_config = {
  enabled_for_disk_encryption = true
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"
}

storage_account_config = {
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  access_tier                   = "Hot"
  account_kind                  = "StorageV2"
  public_network_access_enabled = false
}

log_analytics_workspace_config = {
  sku               = "PerGB2018"
  retention_in_days = 30
}

vnt_address_space = ["192.168.200.0/24"]

web_subnet_config = {
  snt_number           = "01"
  snt_address_prefixes = ["192.168.200.0/25"]
}

int_subnet_config = {
  snt_number           = "02"
  snt_address_prefixes = ["192.168.200.128/25"]
}

public_ip_config = {
  pip_number        = "01"
  allocation_method = "Static"
}