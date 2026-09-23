environment = "dev"
location    = "southcentralus"

replication_type           = "LRS"
blob_versioning_enabled    = true
change_feed_enabled        = false
blob_soft_delete_days      = 7
container_soft_delete_days = 7
enable_delete_lock         = false

network_default_action = "Allow"

tags = {
  owner       = "platform-team"
  cost_center = "CHANGE-ME"
}
