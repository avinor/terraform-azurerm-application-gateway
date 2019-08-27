output "resource_group_name" {
  description = "Resource group name where application gateway is created."
  value       = azurerm_resource_group.main.name
}

output "id" {
  description = "Id of the application gateway."
  value       = azurerm_application_gateway.main.id
}

output "name" {
  description = "Name of the application gateway."
  value       = azurerm_application_gateway.main.name
}

output "user_assigned_identity" {
  description = "Resource id and client id of the user assigned identity."
  value = {
    id        = azurerm_user_assigned_identity.main.id
    client_id = azurerm_user_assigned_identity.main.client_id
  }
}