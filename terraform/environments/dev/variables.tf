variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "eu-north-1"
}

variable "alert_email" {
  description = "Email address to receive security alerts via SNS. Leave as \"\" to skip the subscription (you can confirm the subscription later by re-running apply)."
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "AWS region to deploy resources into."
  type        = string
  default     = "eu-north-1"
}
