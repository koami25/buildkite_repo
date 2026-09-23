# Remote state for uat. Each environment gets its own state file.
resource_group_name  = "rg_charm_online_sand"
storage_account_name = "sttofustatefilessanddev"
container_name       = "buildkitedemo"
key                  = "storage/uat.terraform.tfstate"
