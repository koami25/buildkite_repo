variable "name" {
  description = "Globally unique storage account name (3-24 lowercase letters and digits)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "name must be 3-24 characters, lowercase letters and digits only."
  }
}

variable "resource_group_name" {
  description = "Resource group to deploy into."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "account_tier" {
  description = "Standard or Premium."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "account_tier must be Standard or Premium."
  }
}

variable "replication_type" {
  description = "LRS, ZRS, GRS, RAGRS, GZRS or RAGZRS."
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "RAGRS", "GZRS", "RAGZRS"], var.replication_type)
    error_message = "replication_type must be one of LRS, ZRS, GRS, RAGRS, GZRS, RAGZRS."
  }
}

variable "access_tier" {
  description = "Hot or Cool."
  type        = string
  default     = "Hot"
}

variable "shared_access_key_enabled" {
  description = "Allow account-key/SAS auth. Keep false to force Entra ID (RBAC) auth."
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Allow access over the public endpoint (still subject to network_rules)."
  type        = bool
  default     = true
}

variable "network_default_action" {
  description = "Allow or Deny traffic not matched by ip_rules / subnet_ids."
  type        = string
  default     = "Allow"

  validation {
    condition     = contains(["Allow", "Deny"], var.network_default_action)
    error_message = "network_default_action must be Allow or Deny."
  }
}

variable "allowed_ip_rules" {
  description = "Public IPs/CIDRs allowed when network_default_action is Deny."
  type        = list(string)
  default     = []
}

variable "allowed_subnet_ids" {
  description = "Subnet IDs allowed when network_default_action is Deny."
  type        = list(string)
  default     = []
}

variable "infrastructure_encryption_enabled" {
  description = "Double encryption at the infrastructure layer (forces new resource if changed)."
  type        = bool
  default     = true
}

variable "blob_versioning_enabled" {
  description = "Keep previous versions of blobs."
  type        = bool
  default     = true
}

variable "change_feed_enabled" {
  description = "Record a log of blob changes."
  type        = bool
  default     = false
}

variable "blob_soft_delete_days" {
  description = "Days deleted blobs are recoverable."
  type        = number
  default     = 7

  validation {
    condition     = var.blob_soft_delete_days >= 1 && var.blob_soft_delete_days <= 365
    error_message = "blob_soft_delete_days must be between 1 and 365."
  }
}

variable "container_soft_delete_days" {
  description = "Days deleted containers are recoverable."
  type        = number
  default     = 7

  validation {
    condition     = var.container_soft_delete_days >= 1 && var.container_soft_delete_days <= 365
    error_message = "container_soft_delete_days must be between 1 and 365."
  }
}

variable "enable_delete_lock" {
  description = "Add a CanNotDelete management lock (needs Owner or User Access Administrator)."
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Send blob diagnostic logs here. null disables diagnostics."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags for all resources in this module."
  type        = map(string)
  default     = {}
}
