output "vmss" {
  value     = module.scaleset.vmss
  sensitive = true
}

output "subscriptionId" {
  value = module.kv.subscriptionId
}
