provider "azurerm" {
  features {}
}

module "rg" {
  source = "github.com/cloudnationhq/az-cn-module-tf-rg"

  environment = var.environment

  groups = {
    demo = {
      region = "westeurope"
    }
  }
}

module "cosmosdb" {
  source = "../.."

  workload    = var.workload
  environment = var.environment

  cosmosdb = {
    location      = module.rg.groups.demo.location
    resourcegroup = module.rg.groups.demo.name
    kind          = "MongoDB"
    capabilities  = ["EnableMongo"]

    geo_location = {
      weu = {
        location          = "westeurope"
        failover_priority = 0
      }
    }

    databases = {
      mongo = {
        db1 = {
          throughput = 400
          collections = {
            col1 = {
              throughput = 400
            }
          }
        }
        db2 = {
          throughput = 400
          collections = {
            col1 = {
              throughput = 400
            }
          }
        }
      }
    }
  }
  depends_on = [module.rg]
}
