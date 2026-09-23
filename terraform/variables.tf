variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "environment must be dev, uat or prod."
  }
}

variable "project" {
  description = "Short project code used in resource names (lowercase letters/digits)."
  type        = string
  default     = "bkdemo"

  validation {
    condition     = can(regex("^[a-z0-9]{2,10}$", var.project))
    error_message = "project must be 2-10 lowercase letters or digits."
  }
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "southcentralus"
}

variable "instance" {
  description = "Two-digit instance number, lets you run side-by-side copies."
  type        = string
  default     = "01"
}

variable "storage_account_name" {
  description = "Override the generated storage account name (null = use naming convention)."
  type        = string
  default     = null
}

variable "replication_type" {
  description = "LRS, ZRS, GRS, RAGRS, GZRS or RAGZRS."
  type        = string
  default     = "LRS"
}

variable "access_tier" {
  description = "Hot or Cool."
  type        = string
  default     = "Hot"
}

variable "network_default_action" {
  description = "Allow or Deny traffic not matched by allowed_ip_rules / allowed_subnet_ids."
  type        = string
  default     = "Allow"
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

variable "blob_versioning_enabled" {
  type    = bool
  default = true
}

variable "change_feed_enabled" {
  type    = bool
  default = false
}

variable "blob_soft_delete_days" {
  type    = number
  default = 7
}

variable "container_soft_delete_days" {
  type    = number
  default = 7
}

variable "enable_delete_lock" {
  description = "Add a CanNotDelete lock on the storage account."
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace for diagnostics (null disables)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Extra tags merged onto the standard ones."
  type        = map(string)
  default     = {}
}
