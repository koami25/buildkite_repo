environment = "uat"
location    = "southcentralus"

replication_type           = "ZRS"
blob_versioning_enabled    = true
change_feed_enabled        = false
blob_soft_delete_days      = 14
container_soft_delete_days = 14
enable_delete_lock         = false

network_default_action = "Allow"

tags = {
  owner       = "platform-team"
  cost_center = "CHANGE-ME"
}
