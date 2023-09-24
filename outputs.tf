output "account" {
  value = azurerm_cosmosdb_account.db
}

output "subscriptionId" {
  value = data.azurerm_subscription.current.subscription_id
}

output "mongodb" {
  value = azurerm_cosmosdb_mongo_database.mongodb
}

output "mongodb_collection" {
  value = azurerm_cosmosdb_mongo_collection.mongodb_collection
}

output "tables" {
  value = azurerm_cosmosdb_table.tables
}

output "sqldb" {
  value = azurerm_cosmosdb_sql_database.sqldb
}

output "sql_container" {
  value = azurerm_cosmosdb_sql_container.sqlc
}
