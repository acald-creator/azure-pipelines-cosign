variable "resource_group_name_prefix" {
  default     = "phxvlabs-dev-rg-"
  description = "Prefix of the resource group that is combined with a random ID"
}

variable "location" {
  type        = string
  description = "Define the region the Azure Kay Vault will be created in."
  default     = "eastus"
}

variable "name" {
  type        = string
  description = "Azure Key Vault name"
  default     = "phxvlabs-dev-kv"
}

variable "sku_name" {
  type        = string
  description = "Select Standard of Premium SKU"
  default     = "standard"
}