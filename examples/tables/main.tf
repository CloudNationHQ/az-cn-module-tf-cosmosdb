provider "azurerm" {
  features {}
}

module "naming" {
  source = "github.com/cloudnationhq/az-cn-module-tf-naming"

  suffix = ["demo", "dev"]
}

module "rg" {
  source = "github.com/cloudnationhq/az-cn-module-tf-rg"

  groups = {
    demo = {
      name   = module.naming.resource_group.name
      region = "westeurope"
    }
  }
}

module "cosmosdb" {
  source = "../.."

  cosmosdb = {
    name          = module.naming.cosmosdb_account.name
    location      = module.rg.groups.demo.location
    resourcegroup = module.rg.groups.demo.name
    kind          = "GlobalDocumentDB"
    capabilities  = ["EnableTable"]

    geo_location = {
      weu = {
        location          = "westeurope"
        failover_priority = 0
      }
    }

    tables = {
      table1 = { name = "products", throughput = 400 }
      table2 = { name = "orders", throughput = 400
      }
    }
  }
}
