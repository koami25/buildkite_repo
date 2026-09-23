environment = "prod"
location    = "southcentralus"

replication_type           = "GZRS"
blob_versioning_enabled    = true
change_feed_enabled        = true
blob_soft_delete_days      = 30
container_soft_delete_days = 30

# Requires the deploying identity to have Owner or User Access Administrator
enable_delete_lock = true

# Switch to "Deny" and fill allowed_ip_rules / allowed_subnet_ids (or add
# private endpoints) once the networking for consumers is known.
network_default_action = "Allow"

# log_analytics_workspace_id = "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.OperationalInsights/workspaces/<name>"

tags = {
  owner       = "platform-team"
  cost_center = "CHANGE-ME"
}
