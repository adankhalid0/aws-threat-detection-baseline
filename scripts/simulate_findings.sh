#!/usr/bin/env bash
# Generates GuardDuty sample findings (one per finding type) against the
# detector in this account, to verify the EventBridge -> SNS alerting
# pipeline actually fires end-to-end -- without doing anything actually
# malicious or risky in the account. This is AWS's own supported way to
# test a GuardDuty integration.
#
# Usage:
#   ./scripts/simulate_findings.sh <guardduty-detector-id>
#
# Example (pull the detector ID straight from Terraform output):
#   ./scripts/simulate_findings.sh $(terraform -chdir=terraform/environments/dev output -raw guardduty_detector_id)

set -euo pipefail

DETECTOR_ID="${1:?Usage: $0 <guardduty-detector-id>}"

echo "==> Generating GuardDuty sample findings for detector: ${DETECTOR_ID}"
aws guardduty create-sample-findings --detector-id "${DETECTOR_ID}"

echo ""
echo "==> Done. Sample findings (prefixed [SAMPLE]) typically appear in the GuardDuty"
echo "    console within a minute, and are automatically imported into Security Hub."
echo "    The alert email arrives once EventBridge processes them (depends on"
echo "    finding_publishing_frequency; default here is 15 minutes)."
echo ""
echo "Next steps:"
echo "  1. Check the GuardDuty console for the [SAMPLE] findings."
echo "  2. Check Security Hub -- the same findings should appear there too."
echo "  3. Confirm the alert email arrived from the SNS topic."
echo "  4. Document what you saw in docs/DETECTION_FINDINGS.md."
