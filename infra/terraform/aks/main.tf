data "azurerm_resource_group" "platform" {
  name = var.resource_group_name
}

resource "azurerm_container_registry" "platform" {
  name                = "${replace(var.project_name, "-", "")}${var.environment}acr"
  resource_group_name = data.azurerm_resource_group.platform.name
  location            = data.azurerm_resource_group.platform.location
  sku                 = "Basic"
  admin_enabled       = false

  tags = var.tags
}
