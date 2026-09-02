output "detector_id" {
  description = "GuardDuty detector ID -- needed by scripts/simulate_findings.sh to generate sample findings."
  value       = aws_guardduty_detector.this.id
}
