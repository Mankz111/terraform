provider "azurerm" {
  features {

  }

}

provider "azuread" {

}


resource "azurerm_resource_group" "terraform-rg" {
  name     = "terraform-rg"
  location = "West Europe"
}

resource "azurerm_container_registry" "acr" {
  name                = "acrterraform"
  resource_group_name = azurerm_resource_group.terraform-rg.name
  location            = azurerm_resource_group.terraform-rg.location
  sku                 = "Basic"
  admin_enabled       = false

}


data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}

resource "azuread_application" "github" {
  display_name = "github-actions-terraform"
  owners       = [data.azuread_client_config.current.object_id]

}

resource "azuread_service_principal" "github" {
  client_id = azuread_application.github.client_id
  owners    = [data.azuread_client_config.current.object_id] # ← e aqui
}

resource "azuread_application_federated_identity_credential" "github" {
  application_id = azuread_application.github.id
  display_name   = "github-actions"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:Mankz111/terraform:environment:main"
}

resource "azurerm_role_assignment" "acr_push" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = azuread_service_principal.github.object_id
}


resource "azurerm_user_assigned_identity" "aci_identity" {
  name                = "aci-identity"
  resource_group_name = azurerm_resource_group.terraform-rg.name
  location            = azurerm_resource_group.terraform-rg.location
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aci_identity.principal_id
}

# resource "azurerm_container_group" "aci" {
#   name                = "aci-minha-app"
#   location            = azurerm_resource_group.terraform-rg.location
#   resource_group_name = azurerm_resource_group.terraform-rg.name
#   os_type             = "Linux"
#   ip_address_type     = "Public"

#   identity {
#     type         = "UserAssigned"
#     identity_ids = [azurerm_user_assigned_identity.aci_identity.id]
#   }

#   image_registry_credential {
#     server   = azurerm_container_registry.acr.login_server
#     user_assigned_identity_id = azurerm_user_assigned_identity.aci_identity.id
#   }

#   container {
#     name   = "minha-app"
#     image  = "${azurerm_container_registry.acr.login_server}/acrterraform:${var.image_tag}"
#     cpu    = "0.5"
#     memory = "1.5"

#     ports {
#       port     = 8080
#       protocol = "TCP"
#     }
#   }
# }

resource "azurerm_role_assignment" "rg_contributor" {
  scope                = azurerm_resource_group.terraform-rg.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github.object_id
}