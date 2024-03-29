locals {
  resource_group_location            = try(data.azurerm_resource_group.parent[0].location, null)
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}

locals {
  existing_group = [for g in data.azuread_groups.existing : g if g.display_name == var.user_group_name]
}

locals {
  group_id = length(local.existing_group) > 0 ? local.existing_group[0].object_id : azuread_group.new[0].object_id
}

# Private endpoint application security group associations
# Remove if this resource does not support private endpoints

locals {
  private_endpoint_application_security_group_associations = { for assoc in flatten([
    for pe_k, pe_v in var.private_endpoints : [
      for asg_k, asg_v in pe_v.application_security_group_associations : {
        asg_key         = asg_k
        pe_key          = pe_k
        asg_resource_id = asg_v
      }
    ]
  ]) : "${assoc.pe_key}-${assoc.asg_key}" => assoc }
}

# Define resource tags
locals {
  tags = {
    cm-resource-parent = azurerm_virtual_desktop_host_pool.hostpool.id
  }
}
