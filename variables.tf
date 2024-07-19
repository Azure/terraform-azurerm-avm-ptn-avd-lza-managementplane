variable "location" {
  type        = string
  description = "(Required) The location/region where the Azure Virtual Desktop resources are located. Changing this forces a new resource to be created."
  nullable    = false
}

variable "log_analytics_workspace_name" {
  type        = string
  description = "The name of the Log Analytics Workspace to use for diagnostics."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which the AVD Private Endpoint should be created."
}

variable "virtual_desktop_application_group_name" {
  type        = string
  description = "(Required) The name of the Virtual Desktop Application Group. Changing the name forces a new resource to be created."
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9-]{3,24}$", var.virtual_desktop_application_group_name))
    error_message = "The name must be between 3 and 24 characters long and can only contain lowercase letters, numbers and dashes."
  }
}

variable "virtual_desktop_application_group_type" {
  type        = string
  description = "(Required) Type of Virtual Desktop Application Group. Valid options are `RemoteApp` or `Desktop` application groups. Changing this forces a new resource to be created."
  nullable    = false
}

variable "virtual_desktop_host_pool_load_balancer_type" {
  type        = string
  description = "(Required) `BreadthFirst` load balancing distributes new user sessions across all available session hosts in the host pool. Possible values are `BreadthFirst`, `DepthFirst` and `Persistent`. `DepthFirst` load balancing distributes new user sessions to an available session host with the highest number of connections but has not reached its maximum session limit threshold. `Persistent` should be used if the host pool type is `Personal`"
  nullable    = false
}

variable "virtual_desktop_host_pool_name" {
  type        = string
  description = "(Required) The name of the Virtual Desktop Host Pool. Changing this forces a new resource to be created."
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9-]{3,24}$", var.virtual_desktop_host_pool_name))
    error_message = "The name must be between 3 and 24 characters long and can only contain lowercase letters, numbers and dashes."
  }
}

variable "virtual_desktop_host_pool_type" {
  type        = string
  description = "(Required) The type of the Virtual Desktop Host Pool. Valid options are `Personal` or `Pooled`. Changing the type forces a new resource to be created."
  nullable    = false
}

variable "virtual_desktop_scaling_plan_name" {
  type        = string
  description = "(Required) The name which should be used for this Virtual Desktop Scaling Plan . Changing this forces a new Virtual Desktop Scaling Plan to be created."
  nullable    = false
}

variable "virtual_desktop_scaling_plan_time_zone" {
  type        = string
  description = "(Required) Specifies the Time Zone which should be used by the Scaling Plan for time based events, [the possible values are defined here](https://jackstromberg.com/2017/01/list-of-time-zones-consumed-by-azure/)."
  nullable    = false
}

variable "virtual_desktop_workspace_name" {
  type        = string
  description = "(Required) The name of the Virtual Desktop Workspace. Changing this forces a new resource to be created."
  nullable    = false
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.

For more information see <https://aka.ms/avm/telemetryinfo>.

If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

# tflint-ignore: terraform_unused_declarations
variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Controls the Managed Identity configuration on this resource. The following properties can be specified:

- `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
- `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
DESCRIPTION
  nullable    = false
}

# tflint-ignore: terraform_unused_declarations
variable "private_endpoints" {
  type = map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    lock = optional(object({
      name = optional(string, null)
      kind = string
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
  default     = {}
  description = <<DESCRIPTION
A map of private endpoints to create on the resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
- `name` - (Optional) The name of the private endpoint. One will be generated if not set.
- `role_assignments` - (Optional) A map of role assignments to create on the private endpoint. Each role assignment should include a `role_definition_id_or_name` and a `principal_id`.
- `lock` - (Optional) The lock level to apply to the private endpoint. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.
- `tags` - (Optional) A mapping of tags to assign to the private endpoint. Each tag should be a string.
- `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
- `private_dns_zone_group_name` - (Optional) The name of the private DNS zone group. One will be generated if not set.
- `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
- `application_security_group_resource_ids` - (Optional) A map of resource IDs of application security groups to associate with the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
- `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
- `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
- `location` - (Optional) The Azure location where the resources will be deployed. Defaults to the location of the resource group.
- `resource_group_name` - (Optional) The resource group where the resources will be deployed. Defaults to the resource group of the resource.
- `ip_configurations` - (Optional) A map of IP configurations to create on the private endpoint. If not specified the platform will create one. Each IP configuration should include a `name` and a `private_ip_address`.
DESCRIPTION
  nullable    = false
}

# tflint-ignore: terraform_unused_declarations
variable "public_network_access_enabled" {
  type        = bool
  default     = true
  description = "Whether or not public network access is enabled for the AVD Workspace."
}

variable "registration_expiration_period" {
  type        = string
  default     = "48h"
  description = "The expiration period for the registration token. Must be less than or equal to 30 days."

  validation {
    condition = can(regex("^(\\d+)([smhdw])$", var.registration_expiration_period)) && (
      (tonumber(regex("\\d+", var.registration_expiration_period)) <= 30 && regex("\\D", var.registration_expiration_period) == "d") ||
      (regex("\\D", var.registration_expiration_period) != "d")
    )
    error_message = "The expiration period must be a valid duration string and less than or equal to 30 days."
  }
}

# tflint-ignore: terraform_unused_declarations
variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
  A map of role assignments to create on the resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  
  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `principal_id` - The ID of the principal to assign the role to.
  - `description` - The description of the role assignment.
  - `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
  - `condition` - The condition which will be used to scope the role assignment.
  - `condition_version` - The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  
  > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
  DESCRIPTION
  nullable    = false
}

# tflint-ignore: terraform_unused_declarations
variable "schedules" {
  type = map(object({
    name                                 = string
    days_of_week                         = set(string)
    off_peak_start_time                  = string
    off_peak_load_balancing_algorithm    = string
    ramp_down_capacity_threshold_percent = number
    ramp_down_force_logoff_users         = bool
    ramp_down_load_balancing_algorithm   = string
    ramp_down_minimum_hosts_percent      = number
    ramp_down_notification_message       = string
    ramp_down_start_time                 = string
    ramp_down_stop_hosts_when            = string
    ramp_down_wait_time_minutes          = number
    peak_start_time                      = string
    peak_load_balancing_algorithm        = string
    ramp_up_capacity_threshold_percent   = optional(number)
    ramp_up_load_balancing_algorithm     = string
    ramp_up_minimum_hosts_percent        = optional(number)
    ramp_up_start_time                   = string
  }))
  default = {
    schedule1 = {
      name                                 = "Weekdays"
      days_of_week                         = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
      ramp_up_start_time                   = "05:00"
      ramp_up_load_balancing_algorithm     = "BreadthFirst"
      ramp_up_minimum_hosts_percent        = 20
      ramp_up_capacity_threshold_percent   = 10
      peak_start_time                      = "09:00"
      peak_load_balancing_algorithm        = "BreadthFirst"
      ramp_down_start_time                 = "19:00"
      ramp_down_load_balancing_algorithm   = "DepthFirst"
      ramp_down_minimum_hosts_percent      = 10
      ramp_down_force_logoff_users         = false
      ramp_down_wait_time_minutes          = 45
      ramp_down_notification_message       = "Please log off in the next 45 minutes..."
      ramp_down_capacity_threshold_percent = 5
      ramp_down_stop_hosts_when            = "ZeroSessions"
      off_peak_start_time                  = "22:00"
      off_peak_load_balancing_algorithm    = "DepthFirst"
    }
  }
  description = <<DESCRIPTION
A map of schedules to create on AVD Scaling Plan. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` -  The name of the schedule.
- `days_of_week` -  The days of the week to apply the schedule to. 
- `off_peak_start_time` -  The start time of the off peak period. 
- `off_peak_load_balancing_algorithm` -  The load balancing algorithm to use during the off peak period. 
- `ramp_down_capacity_threshold_percent` -  The capacity threshold percentage to use during the ramp down period. 
- `ramp_down_force_logoff_users` -  Whether to force log off users during the ramp down period. 
- `ramp_down_load_balancing_algorithm` -  The load balancing algorithm to use during the ramp down period. 
- `ramp_down_minimum_hosts_percent` -  The minimum hosts percentage to use during the ramp down period. 
- `ramp_down_notification_message` -  The notification message to use during the ramp down period. 
- `ramp_down_start_time` -  The start time of the ramp down period. 
- `ramp_down_stop_hosts_when` -  When to stop hosts during the ramp down period. 
- `ramp_down_wait_time_minutes` -  The wait time in minutes to use during the ramp down period. 
- `peak_start_time` -  The start time of the peak period. 
- `peak_load_balancing_algorithm` -  The load balancing algorithm to use during the peak period. 
- `ramp_up_capacity_threshold_percent` - (Optional) The capacity threshold percentage to use during the ramp up period. 
- `ramp_up_load_balancing_algorithm` -  The load balancing algorithm to use during the ramp up period. 
- `ramp_up_minimum_hosts_percent` - (Optional) The minimum hosts percentage to use during the ramp up period. 
- `ramp_up_start_time` -  The start time of the ramp up period. 
DESCRIPTION
  nullable    = false

  validation {
    condition = alltrue(
      [
        for _, v in var.schedules :
        v.days_of_week != null || v.off_peak_start_time != null || v.off_peak_load_balancing_algorithm != null || v.ramp_down_capacity_threshold_percent != null || v.ramp_down_force_logoff_users != null || v.ramp_down_load_balancing_algorithm != null || v.ramp_down_minimum_hosts_percent != null || v.ramp_down_notification_message != null || v.ramp_down_start_time != null || v.ramp_down_stop_hosts_when != null || v.ramp_down_wait_time_minutes != null || v.ramp_up_capacity_threshold_percent != null || v.ramp_up_load_balancing_algorithm != null || v.ramp_up_minimum_hosts_percent != null || v.ramp_up_start_time != null
      ]
    )
    error_message = "At least one of `days_of_week`, `off_peak_start_time`, `off_peak_load_balancing_algorithm`, `ramp_down_capacity_threshold_percent`, `ramp_down_force_logoff_users`, `ramp_down_load_balancing_algorithm`, `ramp_down_minimum_hosts_percent`, `ramp_down_notification_message`, `ramp_down_start_time`, `ramp_down_stop_hosts_when`, `ramp_down_wait_time_minutes`, `ramp_up_capacity_threshold_percent`, `ramp_up_load_balancing_algorithm`, `ramp_up_minimum_hosts_percent`, or `ramp_up_start_time`, must be set."
  }
}

variable "subresource_names" {
  type        = list(string)
  default     = []
  description = "The names of the subresources to assosciatied with the private endpoint. The target subresource must be one of: 'feed', or 'global'."
}

# tflint-ignore: terraform_unused_declarations
variable "time_zone" {
  type        = string
  default     = "Eastern Standard Time"
  description = "The time zone of the AVD Scaling Plan."
}

# tflint-ignore: terraform_unused_declarations
variable "tracing_tags_enabled" {
  type        = bool
  default     = false
  description = "Whether enable tracing tags that generated by BridgeCrew Yor."
  nullable    = false
}

# tflint-ignore: terraform_unused_declarations
variable "tracing_tags_prefix" {
  type        = string
  default     = "avm_"
  description = "Default prefix for generated tracing tags"
  nullable    = false
}

# tflint-ignore: terraform_unused_declarations
variable "virtual_desktop_application_group_default_desktop_display_name" {
  type        = string
  default     = null
  description = "(Optional) Option to set the display name for the default sessionDesktop desktop when `type` is set to `Desktop`."
}

# tflint-ignore: terraform_unused_declarations
variable "virtual_desktop_application_group_description" {
  type        = string
  default     = null
  description = "(Optional) Option to set a description for the Virtual Desktop Application Group."
}

# tflint-ignore: terraform_unused_declarations
variable "virtual_desktop_application_group_friendly_name" {
  type        = string
  default     = null
  description = "(Optional) Option to set a friendly name for the Virtual Desktop Application Group."
}

# tflint-ignore: terraform_unused_declarations
variable "virtual_desktop_application_group_tags" {
  type        = map(string)
  default     = null
  description = "(Optional) A mapping of tags to assign to the resource."
}

# tflint-ignore: terraform_unused_declarations
variable "virtual_desktop_application_group_timeouts" {
  type = object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
  default     = null
  description = <<-EOT
 - `create` - (Defaults to 60 minutes) Used when creating the Virtual Desktop Application Group.
 - `delete` - (Defaults to 60 minutes) Used when deleting the Virtual Desktop Application Group.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Virtual Desktop Application Group.
 - `update` - (Defaults to 60 minutes) Used when updating the Virtual Desktop Application Group.
EOT
}

variable "virtual_desktop_host_pool_custom_rdp_properties" {
  type        = string
  default     = "drivestoredirect:s:*;audiomode:i:0;videoplaybackmode:i:1;redirectclipboard:i:1;redirectprinters:i:1;devicestoredirect:s:*;redirectcomports:i:1;redirectsmartcards:i:1;usbdevicestoredirect:s:*;enablecredsspsupport:i:1;use multimon:i:0"
  description = "(Optional) A valid custom RDP properties string for the Virtual Desktop Host Pool, available properties can be [found in this article](https://docs.microsoft.com/windows-server/remote/remote-desktop-services/clients/rdp-files)."
}

# tflint-ignore: terraform_unused_declarations
variable "virtual_desktop_host_pool_description" {
  type        = string
  default     = null
  description = "(Optional) A description for the Virtual Desktop Host Pool."
}

# tflint-ignore: terraform_unused_declarations
variable "virtual_desktop_host_pool_friendly_name" {
  type        = string
  default     = null
  description = "(Optional) A friendly name for the Virtual Desktop Host Pool."
}

variable "virtual_desktop_host_pool_maximum_sessions_allowed" {
  type        = number
  default     = null
  description = "(Optional) A valid integer value from 0 to 999999 for the maximum number of users that have concurrent sessions on a session host. Should only be set if the `type` of your Virtual Desktop Host Pool is `Pooled`."
}

# tflint-ignore: terraform_unused_declarations
variable "virtual_desktop_host_pool_personal_desktop_assignment_type" {
  type        = string
  default     = null
  description = "(Optional) `Automatic` assignment"
}

# tflint-ignore: terraform_unused_declarations
variable "virtual_desktop_host_pool_preferred_app_group_type" {
  type        = string
  default     = null
  description = "Preferred App Group type to display"
}

# tflint-ignore: terraform_unused_declarations
variable "virtual_desktop_host_pool_scheduled_agent_updates" {
  type = object({
    enabled                   = optional(bool)
    timezone                  = optional(string)
    use_session_host_timezone = optional(bool)
    schedule = optional(list(object({
      day_of_week = string
      hour_of_day = number
    })))
  })
  default     = null
  description = <<-EOT
 - `enabled` - (Optional) Enables or disables scheduled updates of the AVD agent components (RDAgent, Geneva Monitoring agent, and side-by-side stack) on session hosts. If this is enabled then up to two `schedule` blocks must be defined. Default is `false`.
 - `timezone` - (Optional) Specifies the time zone in which the agent update schedule will apply. If `use_session_host_timezone` is enabled then it will override this setting. Default is `UTC`
 - `use_session_host_timezone` - (Optional) Specifies whether scheduled agent updates should be applied based on the timezone of the affected session host. If configured then this setting overrides `timezone`. Default is `false`.

 ---
 `schedule` block supports the following:
 - `day_of_week` - (Required) The day of the week on which agent updates should be performed. Possible values are `Monday`, `Tuesday`, `Wednesday`, `Thursday`, `Friday`, `Saturday`, and `Sunday`
 - `hour_of_day` - (Required) The hour of day the update window should start. The update is a 2 hour period following the hour provided. The value should be provided as a number between 0 and 23, with 0 being midnight and 23 being 11pm. A leading zero should not be used.
EOT
}

variable "virtual_desktop_host_pool_start_vm_on_connect" {
  type        = bool
  default     = null
  description = "(Optional) Enables or disables the Start VM on Connection Feature. Defaults to `false`."
}

# tflint-ignore: terraform_unused_declarations
variable "virtual_desktop_host_pool_tags" {
  type        = map(string)
  default     = null
  description = "(Optional) A mapping of tags to assign to the resource."
}

# tflint-ignore: terraform_unused_declarations
variable "virtual_desktop_host_pool_timeouts" {
  type = object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
  default     = null
  description = <<-EOT
 - `create` - (Defaults to 60 minutes) Used when creating the Virtual Desktop Host Pool.
 - `delete` - (Defaults to 60 minutes) Used when deleting the Virtual Desktop Host Pool.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Virtual Desktop Host Pool.
 - `update` - (Defaults to 60 minutes) Used when updating the Virtual Desktop Host Pool.
EOT
}

# tflint-ignore: terraform_unused_declarations
variable "virtual_desktop_host_pool_validate_environment" {
  type        = bool
  default     = null
  description = "(Optional) Allows you to test service changes before they are deployed to production. Defaults to `false`."
}

# tflint-ignore: terraform_unused_declarations
variable "virtual_desktop_scaling_plan_description" {
  type        = string
  default     = null
  description = "(Optional) A description of the Scaling Plan."
}

# tflint-ignore: terraform_unused_declarations
variable "virtual_desktop_scaling_plan_exclusion_tag" {
  type        = string
  default     = null
  description = "(Optional) The name of the tag associated with the VMs you want to exclude from autoscaling."
}

# tflint-ignore: terraform_unused_declarations
variable "virtual_desktop_scaling_plan_friendly_name" {
  type        = string
  default     = null
  description = "(Optional) Friendly name of the Scaling Plan."
}

# tflint-ignore: terraform_unused_declarations
variable "virtual_desktop_scaling_plan_host_pool" {
  type = list(object({
    hostpool_id          = string
    scaling_plan_enabled = bool
  }))
  default     = null
  description = <<-EOT
 - `hostpool_id` - (Required) The ID of the HostPool to assign the Scaling Plan to.
 - `scaling_plan_enabled` - (Required) Specifies if the scaling plan is enabled or disabled for the HostPool.
EOT
}

# tflint-ignore: terraform_unused_declarations
variable "virtual_desktop_scaling_plan_tags" {
  type        = map(string)
  default     = null
  description = "(Optional) A mapping of tags which should be assigned to the Virtual Desktop Scaling Plan ."
}

# tflint-ignore: terraform_unused_declarations
variable "virtual_desktop_scaling_plan_timeouts" {
  type = object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
  default     = null
  description = <<-EOT
 - `create` - (Defaults to 1 hour) Used when creating the Virtual Desktop Scaling Plan.
 - `delete` - (Defaults to 1 hour) Used when deleting the Virtual Desktop Scaling Plan.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Virtual Desktop Scaling Plan.
 - `update` - (Defaults to 1 hour) Used when updating the Virtual Desktop Scaling Plan.
EOT
}

# tflint-ignore: terraform_unused_declarations
variable "virtual_desktop_workspace_description" {
  type        = string
  default     = null
  description = "(Optional) A description for the Virtual Desktop Workspace."
}

# tflint-ignore: terraform_unused_declarations
variable "virtual_desktop_workspace_friendly_name" {
  type        = string
  default     = null
  description = "(Optional) A friendly name for the Virtual Desktop Workspace."
}

# tflint-ignore: terraform_unused_declarations
variable "virtual_desktop_workspace_public_network_access_enabled" {
  type        = bool
  default     = null
  description = "(Optional) Whether public network access is allowed for this Virtual Desktop Workspace. Defaults to `true`."
}

# tflint-ignore: terraform_unused_declarations
variable "virtual_desktop_workspace_tags" {
  type        = map(string)
  default     = null
  description = "(Optional) A mapping of tags to assign to the resource."
}

# tflint-ignore: terraform_unused_declarations
variable "virtual_desktop_workspace_timeouts" {
  type = object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
  default     = null
  description = <<-EOT
 - `create` - (Defaults to 60 minutes) Used when creating the Virtual Desktop Workspace.
 - `delete` - (Defaults to 60 minutes) Used when deleting the Virtual Desktop Workspace.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Virtual Desktop Workspace.
 - `update` - (Defaults to 60 minutes) Used when updating the Virtual Desktop Workspace.
EOT
}
