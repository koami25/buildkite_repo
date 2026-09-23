# Remote state for dev. Each environment gets its own state file.
resource_group_name  = "rg_charm_online_sand"
storage_account_name = "sttofustatefilessanddev"
container_name       = "buildkitedemo"
key                  = "storage/dev.terraform.tfstate"
