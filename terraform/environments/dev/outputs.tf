output "guardduty_detector_id" {
  description = "GuardDuty detector ID -- pass this to scripts/simulate_findings.sh"
  value       = module.guardduty.detector_id
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic security alerts are published to."
  value       = module.alerting.topic_arn
}
