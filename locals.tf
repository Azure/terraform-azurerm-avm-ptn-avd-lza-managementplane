locals {
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
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
    cm-resource-parent = module.avm_res_desktopvirtualization_hostpool.resource.id
  }
}

# We pick a random region from this list.
locals {
  azure_regions = [
    "ukwest",
    "uksouth",
    "centralindia",
    "australiaeast",
    "canadacentral",
    "canadaeast",
    "japaneast",
    "westeurope",
    "northeurope",
    "eastus",
    "eastus2",
    "westus",
    "westus2",
    "westus3",
    "southcentralus",
    "northcentralus",
    "centralus",
    "westcentralus"
  ]
}
