variable "tenant_id" {
  type        = string
  description = "(Required) The Tenant ID which should be used."
}

variable "subscription_id" {
  type        = string
  description = "(Required) The Subscription ID which should be used."
}

variable "client_id" {
  type        = string
  sensitive   = true
  description = "(Required) The Subscription ID which should be used."
}

variable "client_secret" {
  type        = string
  sensitive   = true
  description = "(Required) The Client ID which should be used."
}

variable "object_id" {
  type        = string
  sensitive   = true
  description = "(Required) The object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault."
}

// NAMING
variable "project_name" {
  type        = string
  default     = "fpproject"
  description = "(Optional) Name of the project. Used for naming. It needs to be 9 chatrachters long."

  validation {
    condition     = length(var.project_name) == 9
    error_message = <<EOF
        INCORRECT PARAMETER: "project_name" needs to be 9 charachters.
    EOF
  }
}

variable "resource_sequence" {
  type        = string
  default     = "001"
  description = "(Optional) Name of the project. Used for naming. It needs to be 3 chatrachters long."

  validation {
    condition     = length(var.resource_sequence) == 3
    error_message = <<EOF
        INCORRECT PARAMETER: "resource_sequence" needs to be 3 charachters.
    EOF
  }
}

// COMMON
variable "location" {
  type        = string
  default     = "West Europe"
  description = "(Optional) Valid Azure location in which all the resources will be created."

  validation {
    condition     = contains(["West Europe", "North Europe"], var.location)
    error_message = <<EOF
        INCORRECT PARAMETER: Allowed values for "location" parameter are: "West Europe", "North Europe". 
    EOF
  }
}

// AZURE KEY VAULT 
variable "azure_key_vault_config" {
  type = any
}

// STORAGE ACCUNT
variable "storage_account_config" {
  type = any
}

// TAGGING
variable "env_tag" {
  type        = string
  description = "(Optional) Tag specifying environment in which project is deployed."
  default     = ""
}

variable "log_analytics_workspace_config" {
  type = any
}

variable "vnt_address_space" {
  type        = list(string)
  description = "(Required) The address space that is used the virtual network."
}

variable "subnet_config" {
  type        = any
  description = "(Required) Subnet configuration for virtual network."
}

variable "public_ip_config" {
  type = any
}

variable "vm_size" {
  type    = string
  default = "Standard_DS1_v2"
}

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}