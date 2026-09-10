# AWS Security Hub -- aggregates findings from GuardDuty (and other
# services) into one place, and continuously checks the account against
# the CIS AWS Foundations Benchmark 3.0 -- the same benchmark the
# companion aws-cloud-security-baseline project audits with Prowler as a
# one-off scan. Security Hub runs the equivalent checks natively and
# continuously instead, which is the more realistic setup for an account
# someone is actually operating day to day.

resource "aws_securityhub_account" "this" {
  enable_default_standards = false
}

resource "aws_securityhub_standards_subscription" "cis" {
  standards_arn = "arn:aws:securityhub:${var.region}::standards/cis-aws-foundations-benchmark/v/3.0.0"
  depends_on    = [aws_securityhub_account.this]
}
