# generate random id
resource "random_string" "random" {
  length    = 3
  min_lower = 3
  special   = false
  numeric   = false
  upper     = false
}

# cosmosdb account
resource "azurerm_cosmosdb_account" "db" {
  name                      = "cosmos-${var.workload}-${var.environment}-${random_string.random.result}"
  location                  = var.cosmosdb.location
  resource_group_name       = var.cosmosdb.resourcegroup
  offer_type                = try(var.cosmosdb.offer_type, "Standard")
  kind                      = var.cosmosdb.kind
  enable_automatic_failover = try(var.cosmosdb.enable.automatic_failover, false)
  enable_free_tier          = try(var.cosmosdb.enable.free_tier, false)
  network_acl_bypass_ids    = try(var.cosmosdb.network_acl_bypass_ids, [])
  mongo_server_version      = var.cosmosdb.kind == "MongoDB" ? try(var.cosmosdb.mongo_server_version, "4.2") : null

  access_key_metadata_writes_enabled    = try(var.cosmosdb.enable.access_key_metadata_writes, false)
  enable_multiple_write_locations       = try(var.cosmosdb.enable.multiple_write_locations, false)
  local_authentication_disabled         = try(var.cosmosdb.enable.local_authentication_disabled, false)
  network_acl_bypass_for_azure_services = try(var.cosmosdb.enable.network_acl_bypass_for_azure_services, false)
  is_virtual_network_filter_enabled     = try(var.cosmosdb.enable_virtual_network_filter, false)
  public_network_access_enabled         = try(var.cosmosdb.enable.public_network_access, true)
  analytical_storage_enabled            = try(var.cosmosdb.enable.analytical_storage, false)

  dynamic "capabilities" {
    for_each = try(var.cosmosdb.capabilities, [])

    content {
      name = capabilities.value
    }
  }

  dynamic "geo_location" {
    for_each = var.cosmosdb.geo_location
    content {
      location          = geo_location.value.location
      failover_priority = geo_location.value.failover_priority
      zone_redundant    = try(geo_location.value.zone_redundant, false)
    }
  }

  consistency_policy {
    consistency_level       = try(var.cosmosdb.consistency_policy.level, "BoundedStaleness")
    max_interval_in_seconds = try(var.cosmosdb.consistency_policy.max_interval_in_seconds, 300)
    max_staleness_prefix    = try(var.cosmosdb.consistency_policy.max_staleness_prefix, 100000)
  }
}

# mongo databases
resource "azurerm_cosmosdb_mongo_database" "mongodb" {
  for_each = try(var.cosmosdb.databases.mongo, {})

  name                = "cosmos-mongo-${each.key}"
  account_name        = azurerm_cosmosdb_account.db.name
  resource_group_name = azurerm_cosmosdb_account.db.resource_group_name
  throughput          = each.value.throughput
}

# mongo collections
resource "azurerm_cosmosdb_mongo_collection" "mongodb_collection" {
  for_each = {
    for coll in local.mongo_collections : "${coll.db_key}.${coll.collection_key}" => coll
  }

  name                = each.key
  throughput          = each.value.throughput
  account_name        = azurerm_cosmosdb_account.db.name
  resource_group_name = azurerm_cosmosdb_account.db.resource_group_name
  database_name       = azurerm_cosmosdb_mongo_database.mongodb[each.value.db_key].name

  default_ttl_seconds    = try(each.value.default_ttl_seconds, -1)
  shard_key              = each.value.shard_key

  # conflicts with throughput
  #autoscale_settings {
  #  max_throughput = try(each.value.autoscale_settings.max_throughput, 4000)
  #}

  index {
    keys   = ["_id"]
    unique = true
  }
}

# cosmosdb tables
resource "azurerm_cosmosdb_table" "tables" {
  for_each = try(var.cosmosdb.tables, {})

  name                = "cosmos-table-${each.key}"
  account_name        = azurerm_cosmosdb_account.db.name
  resource_group_name = azurerm_cosmosdb_account.db.resource_group_name
  throughput          = each.value.throughput

  autoscale_settings {
    max_throughput = try(each.value.autoscale_settings.max_throughput, 4000)
  }

  connection {
    endpoint = azurerm_cosmosdb_account.db.endpoint
    key      = azurerm_cosmosdb_account.db.primary_master_key
  }
}

# sql databases
resource "azurerm_cosmosdb_sql_database" "sqldb" {
  for_each = try(var.cosmosdb.databases.sql, {})

  name                = "cosmos-sql-${each.key}"
  account_name        = azurerm_cosmosdb_account.db.name
  resource_group_name = azurerm_cosmosdb_account.db.resource_group_name
  throughput          = each.value.throughput

  # conflicts with throughput
  #autoscale_settings {
  #  max_throughput = try(each.value.autoscale_settings.max_throughput, 4000)
  #}
}

# sql containers
resource "azurerm_cosmosdb_sql_container" "sqlc" {
  for_each = {
    for cont in local.sql_containers : "${cont.db_key}.${cont.container_key}" => cont
  }

  name                  = each.key
  resource_group_name   = azurerm_cosmosdb_account.db.resource_group_name
  account_name          = azurerm_cosmosdb_account.db.name
  database_name         = azurerm_cosmosdb_sql_database.sqldb[each.value.db_key].name
  partition_key_path    = "/definition/id"
  partition_key_version = 1
  throughput            = each.value.throughput
  default_ttl           = try(each.value.default_ttl, -1)

  indexing_policy {
    indexing_mode = each.value.indexing_mode

    dynamic "included_path" {
      for_each = try(each.value.included_paths, [])

      content {
        path = included_path.value
      }
    }

    dynamic "excluded_path" {
      for_each = try(each.value.excluded_paths, [])

      content {
        path = excluded_path.value
      }
    }
  }

  unique_key {
    paths = each.value.unique_key
  }
}

