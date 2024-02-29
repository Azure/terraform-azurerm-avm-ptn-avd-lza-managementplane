# Create Azure Virtual Desktop application group
resource "azurerm_virtual_desktop_application_group" "dag" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  host_pool_id        = azurerm_virtual_desktop_host_pool.hostpool.id
  type                = var.type
  friendly_name       = var.name
  description         = var.description
  tags                = local.tags
}

# Associate the desktop application group with the workspace
resource "azurerm_virtual_desktop_workspace_application_group_association" "workappgrassoc" {
  workspace_id         = azurerm_virtual_desktop_workspace.workspace.id
  application_group_id = azurerm_virtual_desktop_application_group.dag.id

  depends_on = [azurerm_virtual_desktop_workspace.workspace, azurerm_virtual_desktop_application_group.dag]
}

# Get an existing built-in role definition
data "azurerm_role_definition" "role" {
  name = "Desktop Virtualization User"
}

data "azuread_groups" "existing" {
  count         = var.user_group_name == null ? 1 : 0
  display_names = [var.user_group_name]
}

resource "azuread_group" "new" {
  count            = length(local.existing_group) > 0 ? 0 : 1
  display_name     = var.user_group_name
  security_enabled = true
}

resource "azurerm_role_assignment" "role" {
  scope              = azurerm_virtual_desktop_application_group.dag.id
  role_definition_id = data.azurerm_role_definition.role.id
  principal_id       = local.group_id
}

# Create Diagnostic Settings for AVD application group
resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each           = var.diagnostic_settings
  name               = each.value.name != null ? each.value.name : "diag-${var.name}"
  target_resource_id = azurerm_virtual_desktop_application_group.dag.id
  storage_account_id = each.value.storage_account_resource_id

  eventhub_authorization_rule_id = each.value.event_hub_authorization_rule_resource_id
  eventhub_name                  = each.value.event_hub_name
  partner_solution_id            = each.value.marketplace_partner_resource_id
  log_analytics_workspace_id     = each.value.workspace_resource_id

  dynamic "enabled_log" {
    for_each = each.value.log_categories
    content {
      category = enabled_log.value
    }
  }

  dynamic "enabled_log" {
    for_each = each.value.log_groups
    content {
      category_group = enabled_log.value
    }
  }
}

resource "azurerm_role_assignment" "this" {
  for_each                               = var.role_assignments
  scope                                  = azurerm_virtual_desktop_application_group.dag.id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  principal_id                           = each.value.principal_id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
}

resource "azurerm_management_lock" "this" {
  count      = var.lock.kind != "None" ? 1 : 0
  name       = coalesce(var.lock.name, "lock-${var.name}")
  scope      = azurerm_resource_group.this.id
  lock_level = var.lock.kind
}
