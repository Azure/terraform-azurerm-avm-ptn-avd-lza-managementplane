data "azurerm_resource_group" "parent" {
  count = var.location == null ? 1 : 0
  name  = var.resource_group_name
}

resource "azurerm_resource_group" "this" {
  name     = var.name
  location = coalesce(var.location, local.resource_group_location)
  tags     = var.tags
}
