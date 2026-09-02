output "topic_arn" {
  description = "ARN of the SNS topic security alerts are published to."
  value       = aws_sns_topic.security_alerts.arn
}
