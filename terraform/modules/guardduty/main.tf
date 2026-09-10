# Amazon GuardDuty -- continuous, managed threat detection for the AWS
# account. It analyzes CloudTrail management/data events, VPC Flow Logs and
# DNS query logs for indicators of compromise (anomalous API calls, known
# malicious IPs, credential exfiltration patterns, crypto-mining behavior,
# and similar) without requiring any agents or infrastructure of its own.
#
# This is the detection half of the picture the companion
# aws-cloud-security-baseline project doesn't cover: that project is about
# building and auditing configuration (is the account set up correctly).
# This one is about noticing when something is actively going wrong.

# checkov:skip=CKV2_AWS_3: This is a standalone AWS account, not part of an
# AWS Organization, so org-wide GuardDuty enablement (via
# aws_guardduty_organization_configuration) doesn't apply here. Enabling
# GuardDuty directly on the account via this detector resource is the
# correct and complete setup for a single, non-org account.
resource "aws_guardduty_detector" "this" {
  enable                       = true
  finding_publishing_frequency = var.finding_publishing_frequency

  tags = var.tags
}

# S3 protection: analyzes S3 data events (from CloudTrail) for suspicious
# access patterns -- e.g. an identity that starts reading objects from
# every bucket in the account in quick succession.
resource "aws_guardduty_detector_feature" "s3_data_events" {
  detector_id = aws_guardduty_detector.this.id
  name        = "S3_DATA_EVENTS"
  status      = "ENABLED"
}
