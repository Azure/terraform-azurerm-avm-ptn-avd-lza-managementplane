variable "subscription_id" {
  type        = string
  description = "The subscription ID for the Azure account."
}

variable "avd_vm_name" {
  type        = string
  default     = "vm-avd"
  description = "Base name for the Azure Virtual Desktop VMs"
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

variable "tags" {
  type        = map(string)
  default     = { "Owner.Email" : "name@microsoft.com" }
  description = "A map of tags to add to all resources"
}

variable "virtual_desktop_application_group_name" {
  type        = string
  default     = "vdag-avd-001"
  description = "The name of the AVD Application Group."

  validation {
    condition     = can(regex("^[a-z0-9-]{3,24}$", var.virtual_desktop_application_group_name))
    error_message = "The name must be between 3 and 24 characters long and can only contain lowercase letters, numbers and dashes."
  }
}

variable "virtual_desktop_application_group_type" {
  type        = string
  default     = "Desktop"
  description = "The type of the AVD Application Group. Valid values are 'Desktop' and 'RemoteApp'."
}

variable "virtual_desktop_host_pool_friendly_name" {
  type        = string
  default     = "AVD Host Pool"
  description = "(Optional) A friendly name for the Virtual Desktop Host Pool."
}

variable "virtual_desktop_host_pool_load_balancer_type" {
  type        = string
  default     = "BreadthFirst"
  description = "`BreadthFirst` load balancing distributes new user sessions across all available session hosts in the host pool. Possible values are `BreadthFirst`, `DepthFirst` and `Persistent`. `DepthFirst` load balancing distributes new user sessions to an available session host with the highest number of connections but has not reached its maximum session limit threshold. `Persistent` should be used if the host pool type is `Personal`"
}

variable "virtual_desktop_host_pool_maximum_sessions_allowed" {
  type        = number
  default     = 16
  description = "(Optional) A valid integer value from 0 to 999999 for the maximum number of users that have concurrent sessions on a session host. Should only be set if the `type` of your Virtual Desktop Host Pool is `Pooled`."
}

variable "virtual_desktop_host_pool_name" {
  type        = string
  default     = "vdpool-avd-001"
  description = "The name of the AVD Host Pool"
}

variable "virtual_desktop_host_pool_start_vm_on_connect" {
  type        = bool
  default     = true
  description = "(Optional) Enables or disables the Start VM on Connection Feature. Defaults to `false`."
}

variable "virtual_desktop_host_pool_type" {
  type        = string
  default     = "Pooled"
  description = "The type of the AVD Host Pool. Valid values are 'Pooled' and 'Personal'."
}

variable "virtual_desktop_scaling_plan_name" {
  type        = string
  default     = "scp-avd-01"
  description = "The scaling plan for the AVD Host Pool."
}

variable "virtual_desktop_scaling_plan_time_zone" {
  type        = string
  default     = "GMT Standard Time"
  description = "Specifies the Time Zone which should be used by the Scaling Plan for time based events."
}

variable "virtual_desktop_workspace_name" {
  type        = string
  default     = "vdws-avd-001"
  description = "The name of the AVD Workspace"
}

variable "vm_count" {
  type        = number
  default     = 1
  description = "Number of virtual machines to create"
}
