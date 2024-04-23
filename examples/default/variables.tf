variable "description" {
  type        = string
  default     = "AVD Management Plane Deployment"
  description = "The description of the AVD."
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

variable "user_group_name" {
  type        = string
  default     = "avdusersgrp"
  description = "Microsoft Entra ID User Group for AVD users"
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

variable "virtual_desktop_host_pool_load_balancer_type" {
  type        = string
  default     = "BreadthFirst"
  description = "`BreadthFirst` load balancing distributes new user sessions across all available session hosts in the host pool. Possible values are `BreadthFirst`, `DepthFirst` and `Persistent`. `DepthFirst` load balancing distributes new user sessions to an available session host with the highest number of connections but has not reached its maximum session limit threshold. `Persistent` should be used if the host pool type is `Personal`"
}

variable "virtual_desktop_host_pool_name" {
  type        = string
  default     = "vdpool-avd-001"
  description = "The name of the AVD Host Pool"
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
  default     = "Eastern Standard Time"
  description = "Specifies the Time Zone which should be used by the Scaling Plan for time based events, [the possible values are defined here](https://jackstromberg.com/2017/01/list-of-time-zones-consumed-by-azure/)."
}

variable "virtual_desktop_workspace_name" {
  type        = string
  default     = "vdws-avd-001"
  description = "The name of the AVD Workspace"
}
