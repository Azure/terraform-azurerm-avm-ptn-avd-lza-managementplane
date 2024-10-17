# Private endpoint application security group associations
# Remove if this resource does not support private endpoints

# Define resource tags
locals {
  tags = {
    cm-resource-parent = module.avm_res_desktopvirtualization_hostpool.resource.id
  }
}
