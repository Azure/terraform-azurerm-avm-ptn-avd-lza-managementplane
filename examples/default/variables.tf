variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "name" {
  type        = string
  description = "The name of the AVD Application Group."
  default     = "avm-avd"
  validation {
    condition     = can(regex("^[a-z0-9-]{3,24}$", var.name))
    error_message = "The name must be between 3 and 24 characters long and can only contain lowercase letters, numbers and dashes."
  }
}

variable "type" {
  type        = string
  default     = "Desktop"
  description = "The type of the AVD Application Group. Valid values are 'Desktop' and 'RemoteApp'."
}

variable "hostpooltype" {
  type        = string
  description = "The type of the AVD Host Pool. Valid values are 'Pooled' and 'Personal'."
  default     = "Pooled"
}

variable "user_group_name" {
  type        = string
  default     = "avdusersgrp1"
  description = "Microsoft Entra ID User Group for AVD users"
}

variable "description" {
  type        = string
  description = "The description of the AVD."
  default     = "AVD Management Plane Deployment"
}

variable "scalingplan" {
  type        = string
  description = "The scaling plan for the AVD Host Pool."
  default     = "scp-avd-01"
}
