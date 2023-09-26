output "account" {
  value     = module.cosmosdb.account
  sensitive = true
}

output "subscriptionId" {
  value = module.cosmosdb.subscriptionId
}
