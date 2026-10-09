# Routes GuardDuty and Security Hub findings to an SNS topic in near
# real-time via EventBridge, so a detection actually reaches a person
# instead of sitting unread in a console. This is the piece that turns
# "we have a detection tool enabled" into "we get notified when it
# fires" -- the gap a lot of portfolio projects skip.

data "aws_caller_identity" "current" {}

# Customer-managed key for the alerts topic. The AWS-managed key
# (alias/aws/sns) cannot be used here: its key policy does not allow
# EventBridge, so events are silently rejected when they are delivered
# to an encrypted topic.
data "aws_iam_policy_document" "alerts_kms" {
  statement {
    sid       = "EnableAccountAdministration"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid       = "AllowEventBridgeToUseKey"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey*"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "alerts" {
  description             = "Encrypts the security alerts SNS topic and lets EventBridge publish to it."
  enable_key_rotation     = true
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.alerts_kms.json
}

resource "aws_kms_alias" "alerts" {
  name          = "alias/${var.name_prefix}-security-alerts"
  target_key_id = aws_kms_key.alerts.key_id
}

resource "aws_sns_topic" "security_alerts" {
  name              = "${var.name_prefix}-security-alerts"
  kms_master_key_id = aws_kms_key.alerts.arn
}

data "aws_iam_policy_document" "sns_publish" {
  statement {
    sid     = "AllowEventBridgePublish"
    effect  = "Allow"
    actions = ["sns:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.security_alerts.arn]
  }
}

resource "aws_sns_topic_policy" "security_alerts" {
  arn    = aws_sns_topic.security_alerts.arn
  policy = data.aws_iam_policy_document.sns_publish.json
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Every GuardDuty finding, any severity. For a small portfolio account the
# volume is low enough that no severity filter is needed; a production
# account with real traffic would filter to MEDIUM+ here to avoid alert
# fatigue -- worth calling out explicitly rather than pretending this
# scales unchanged.
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "${var.name_prefix}-guardduty-findings"
  description = "Routes all GuardDuty findings to the security-alerts SNS topic."

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
  })
}

resource "aws_cloudwatch_event_target" "guardduty_to_sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "security-alerts-sns"
  arn       = aws_sns_topic.security_alerts.arn
}

# Only CRITICAL/HIGH, active Security Hub findings -- Security Hub's finding
# volume (it imports from multiple sources and re-emits on every update) is
# high enough that alerting on everything would be noise from day one.
resource "aws_cloudwatch_event_rule" "securityhub_findings" {
  name        = "${var.name_prefix}-securityhub-findings"
  description = "Routes new/updated CRITICAL and HIGH Security Hub findings to the security-alerts SNS topic."

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Severity = {
          Label = ["CRITICAL", "HIGH"]
        }
        RecordState = ["ACTIVE"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "securityhub_to_sns" {
  rule      = aws_cloudwatch_event_rule.securityhub_findings.name
  target_id = "security-alerts-sns"
  arn       = aws_sns_topic.security_alerts.arn
}
