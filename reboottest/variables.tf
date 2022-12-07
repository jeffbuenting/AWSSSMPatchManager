# default is in the past to job will not run.
variable "cronjob" {
  description = "cron job schedule"
  type        = string
  default     = "cron(25 11 7 DEC ?)"
}

variable "operation" {
  description = "scan or install patch baseline"
  type        = string
  default     = "scan"
}

variable "sleep_duration" {
  description = "amount of time to sleep between reboot and starting second server."
  type        = string
  default     = "PT20M"
}

variable "SSMAutomationRole" {
  description = "What role should the automations run as"
  type        = string
  default     = "arn:aws:iam::186054512200:role/SSMManagedInstance-Role"
}
