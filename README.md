# Cosmos DB

This Terraform module streamlines the creation and administration of Cosmos DB resources on Azure, offering customizable options for database accounts, consistency levels, throughput settings, and more, to ensure a highly scalable, globally distributed, and secure data management platform in the cloud.

## Goals

The main objective is to create a more logic data structure, achieved by combining and grouping related resources together in a complex object.

The structure of the module promotes reusability. It's intended to be a repeatable component, simplifying the process of building diverse workloads and platform accelerators consistently.

A primary goal is to utilize keys and values in the object that correspond to the REST API's structure. This enables us to carry out iterations, increasing its practical value as time goes on.

A last key goal is to separate logic from configuration in the module, thereby enhancing its scalability, ease of customization, and manageability.

## Features

- supports multiple mongodb databases and collections for efficient data organization
- enables management of multiple sql databases and containers
- utilization of terratest for robust validation.

The below examples shows the usage when consuming the module:

## Usage: simple

```hcl
module "cosmosdb" {
  source = "github.com/cloudnationhq/az-cn-module-tf-cosmosdb"

  cosmosdb = {
    name          = module.naming.cosmosdb_account.name
    location      = module.rg.groups.demo.location
    resourcegroup = module.rg.groups.demo.name
    kind          = "MongoDB"
    capabilities  = ["EnableAggregationPipeline"]

    geo_location = {
      weu = { location = "westeurope", failover_priority = 0 }
    }
  }
}
```

## Usage: mongodb

```hcl
module "cosmosdb" {
  source = "github.com/cloudnationhq/az-cn-module-tf-cosmosdb"

  cosmosdb = {
    name          = module.naming.cosmosdb_account.name
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
      }
    }
  }
}
```

## Usage: sqldb

```hcl
module "cosmosdb" {
  source = "github.com/cloudnationhq/az-cn-module-tf-cosmosdb"

  cosmosdb = {
    name          = module.naming.cosmosdb_account.name
    location      = module.rg.groups.demo.location
    resourcegroup = module.rg.groups.demo.name
    kind          = "GlobalDocumentDB"

    geo_location = {
      weu = {
        location          = "westeurope"
        failover_priority = 0
      }
    }

    databases = {
      sql = {
        db1 = {
          throughput = 400
          containers = {
            sqlc1 = {
              throughput       = 400
              unique_key_paths = ["/definition/idlong"]
              index_policy = {
                indexing_mode  = "consistent"
                included_paths = ["/*"]
              }
            }
          }
        }
      }
    }
  }
}
```

## Usage: tables

```hcl
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
```

## Resources

| Name | Type |
| :-- | :-- |
| [azurerm_cosmosdb_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_account) | resource |
| [random_string](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [azurerm_cosmosdb_mongo_database](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_mongo_database) | resource |
| [azurerm_cosmosdb_mongo_collection](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_mongo_collection) | resource |
| [azurerm_cosmosdb_sql_database](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_database) | resource |
| [azurerm_cosmosdb_sql_container](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_container) | resource |
| [azurerm_cosmosdb_table](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_table) | resource |

## Inputs

| Name | Description | Type | Required |
| :-- | :-- | :-- | :-- |
| `cosmosdb` | describes cosmosdb related configuration | object | yes |

## Outputs

| Name | Description |
| :-- | :-- |
| `account` | contains all cosmosdb account config |
| `subscriptionId` | contains the current subscription id |
| `mongodb` | contains mongodb configuration |
| `mongodb_collection` | contains mongodb collections |
| `tables` | contains cosmosdb tables |
| `sqldb` | contains sql databases |
| `sql_container` | contains sql containers |

## Testing

As a prerequirement, please ensure that both go and terraform are properly installed on your system.

The [Makefile](Makefile) includes two distinct variations of tests. The first one is designed to deploy different usage scenarios of the module. These tests are executed by specifying the TF_PATH environment variable, which determines the different usages located in the example directory.

To execute this test, input the command ```make test TF_PATH=simple```, substituting simple with the specific usage you wish to test.

The second variation is known as a extended test. This one performs additional checks and can be executed without specifying any parameters, using the command ```make test_extended```.

Both are designed to be executed locally and are also integrated into the github workflow.

Each of these tests contributes to the robustness and resilience of the module. They ensure the module performs consistently and accurately under different scenarios and configurations.

## Authors

Module is maintained by [these awesome contributors](https://github.com/cloudnationhq/az-cn-module-tf-cosmosdb/graphs/contributors).

## License

MIT Licensed. See [LICENSE](https://github.com/cloudnationhq/az-cn-module-tf-cosmosdb/blob/main/LICENSE) for full details.

## Reference

- [Documentation](https://learn.microsoft.com/en-us/azure/cosmos-db/)
- [Rest Api](https://learn.microsoft.com/en-us/rest/api/cosmos-db/)
- [Rest Api Specs](https://github.com/Azure/azure-rest-api-specs/tree/main/specification/cosmos-db)
