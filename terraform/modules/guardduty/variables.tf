variable "finding_publishing_frequency" {
  description = "How often GuardDuty exports findings to EventBridge. FIFTEEN_MINUTES gives the fastest feedback loop when testing the alerting pipeline; production accounts with active on-call may prefer the same setting for the same reason."
  type        = string
  default     = "FIFTEEN_MINUTES"
}

variable "tags" {
  description = "Tags applied to the GuardDuty detector."
  type        = map(string)
  default     = {}
}
