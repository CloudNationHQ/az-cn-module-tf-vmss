output "vmss" {
  value = azurerm_linux_virtual_machine_scale_set.vmss
}

output "subscriptionId" {
  value = data.azurerm_subscription.current.subscription_id
}
