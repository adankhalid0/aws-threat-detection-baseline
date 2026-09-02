variable "name_prefix" {
  description = "Prefix for named resources (SNS topic, EventBridge rules)."
  type        = string
  default     = "threat-detection"
}

variable "alert_email" {
  description = "Email address to subscribe to security alerts. Leave as \"\" to skip the subscription (the topic and rules are still created)."
  type        = string
  default     = ""
}
