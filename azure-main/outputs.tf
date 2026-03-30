# output "app_url" {
#   value = "http://${azurerm_container_group.aci.ip_address}:8080"
# }

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "client_id" {
  description = "Client ID para os GitHub Secrets"
  value       = azuread_application.github.client_id
}

output "tenant_id" {
  description = "Tenant ID para os GitHub Secrets"
  value       = data.azurerm_client_config.current.tenant_id
}

output "subscription_id" {
  description = "Subscription ID para os GitHub Secrets"
  value       = data.azurerm_client_config.current.subscription_id
}