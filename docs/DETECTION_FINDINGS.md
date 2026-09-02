# Detection Findings Log

> This file is a template. Fill in the placeholders (marked `TODO`) after
> you've actually deployed the infrastructure and run
> `scripts/simulate_findings.sh` -- the same way `SECURITY_FINDINGS.md` in
> the companion project documents a real run rather than a hypothetical
> one. Paste your real timestamps, finding counts and screenshots in, then
> this note can be deleted.

## 1. Summary

| Step | Timestamp (TODO) | Result |
|------|-------------------|--------|
| GuardDuty + Security Hub enabled | TODO | TODO |
| Sample findings generated (`create-sample-findings`) | TODO | TODO findings generated |
| Findings visible in GuardDuty console | TODO | TODO |
| Findings imported into Security Hub | TODO | TODO |
| Alert email received | TODO | TODO (time from generation to email) |

## 2. What was deployed

- GuardDuty detector, `FIFTEEN_MINUTES` finding publishing frequency, S3 data event protection enabled.
- Security Hub, subscribed to CIS AWS Foundations Benchmark 2.0.
- EventBridge rule routing all GuardDuty findings to SNS.
- EventBridge rule routing CRITICAL/HIGH, active Security Hub findings to the same SNS topic.
- SNS topic, KMS-encrypted (`alias/aws/sns`), with an email subscription.

## 3. Sample findings generated

> TODO: after running `aws guardduty create-sample-findings`, list what
> actually showed up -- GuardDuty generates one sample finding per finding
> type it supports (backdoor, recon, trojan, unauthorized access
> categories, etc.). Note which ones you saw, and whether anything
> surprised you about the finding detail (resource affected, severity
> assigned, description text).

## 4. Alerting pipeline verification

> TODO: did the alert email arrive? How long after the sample findings
> were generated? Did it arrive from the GuardDuty rule, the Security Hub
> rule, or both? If Security Hub's CRITICAL/HIGH filter meant some sample
> findings didn't generate an alert, that's expected -- note which ones
> and why, the same way accepted risks are documented in the companion
> project's findings log rather than treated as failures.

## 5. Security Hub CIS 2.0 standard results

> TODO: once Security Hub has had time to run its checks, note the
> initial compliance score here, same format as the Prowler results in
> the companion project. This will likely differ from the Prowler score
> since Security Hub and Prowler don't implement 100% identical checks --
> worth noting any discrepancy you find, not just the number.

## 6. Lessons learned

> TODO: write this after actually running the project, in your own
> words -- what surprised you, what you'd change for a production
> account, anything that didn't work the way the documentation implied it
> would.

## License

MIT -- see [LICENSE](LICENSE).
