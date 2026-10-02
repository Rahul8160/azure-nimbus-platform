owner = "rahul"

resource_groups = {
  hub = {
    name     = "rg-nimbus-hub-cin"
    location = "centralindia"
    tags     = { layer = "network" }
  }
  workload = {
    name     = "rg-nimbus-workload-cin"
    location = "centralindia"
    tags     = { layer = "workload" }
  }
  shared = {
    name     = "rg-nimbus-shared-cin"
    location = "centralindia"
    tags     = { layer = "shared" }
  }
}