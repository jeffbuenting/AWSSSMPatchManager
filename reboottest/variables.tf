# default is in the past to job will not run.
variable "cronjob" {
  description = "cron job schedule"
  type        = string
  # default     = "cron(15 14 13 DEC ?)"
}

variable "operation" {
  description = "scan or install patch baseline"
  type        = string
  default     = "Install"
}

variable "sleep_duration" {
  description = "amount of time to sleep between reboot and starting second server."
  type        = string
  default     = "PT20M"
}

variable "SSMAutomationRole" {
  description = "What role should the automations run asn (ARN)"
  type        = string
}

variable "aws_region" {
  description = "aws region to install resources."
  type        = string
  default     = "us-east-1"
}

variable "patchgroup" {
  description = "Patch Group to target."
  type        = string
  default     = "UnicaServers"
}
