variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "southcentralus"
}

variable "resource_group_name" {
  description = "Resource group that holds the storage account."
  type        = string
  default     = "rg-buildkite-storage"
}

variable "storage_account_name" {
  description = "Globally unique storage account name (3-24 lowercase letters and digits)."
  type        = string
  default     = "stbuildkitedemo001"

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name must be 3-24 characters, lowercase letters and digits only."
  }
}

variable "account_tier" {
  description = "Storage account tier: Standard or Premium."
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "Replication type: LRS, GRS, RAGRS, ZRS, GZRS or RAGZRS."
  type        = string
  default     = "LRS"
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default = {
    managed_by = "terraform"
    pipeline   = "buildkite"
  }
}
