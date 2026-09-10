# Detection Findings Log

## 1. Summary

| Step | Timestamp (UTC) | Result |
|------|-------------------|--------|
| GuardDuty + Security Hub enabled | 2026-09-10T08:42:30Z | Both enabled successfully via `terraform apply` |
| CIS AWS Foundations Benchmark subscribed | 2026-09-10, shortly after | Subscribed to v3.0.0 (v2.0.0, the originally planned version, does not exist for this account/region -- see "Lessons learned") |
| Sample findings generated (`create-sample-findings`), 1st run | 2026-09-10 | 435 findings generated across all GuardDuty finding types |
| Findings visible in GuardDuty console | Confirmed | All findings show with `[SAMPLE]` prefix in the title |
| Findings imported into Security Hub | Confirmed, via `aws securityhub get-findings` | GuardDuty findings appear with `ProductName: GuardDuty` |
| Real (non-sample) finding: IAM console access setup flagged | 2026-09-10T08:52:37Z | `TTPs/PenTest:IAMUser/KaliLinux` -- GuardDuty flagged `iam:CreateLoginProfile` run from my own machine |
| Real (non-sample) correlated finding: attack sequence | 2026-09-10T08:43:22Z - 09:00:39Z | Critical `AttackSequence:IAM/CompromisedCredentials` finding -- see section 3 |
| SNS email subscription confirmed | TODO: exact time | Initially missed -- `alert_email` variable was left at its default `""`, so no subscription existed at all until fixed (see "Lessons learned") |
| Sample findings generated, 2nd run (post SNS fix) | 2026-09-10 | Run specifically to verify the alert email pipeline end-to-end |
| Alert email received | TODO | TODO (time from generation to email) |

## 2. What was deployed

- GuardDuty detector, `FIFTEEN_MINUTES` finding publishing frequency, S3 data event protection enabled.
- Security Hub, subscribed to **CIS AWS Foundations Benchmark v3.0.0** (not v2.0.0 as originally planned).
- EventBridge rule routing all GuardDuty findings to SNS.
- EventBridge rule routing CRITICAL/HIGH, active Security Hub findings to the same SNS topic.
- SNS topic, KMS-encrypted (`alias/aws/sns`), with an email subscription (conditional on the `alert_email` Terraform variable -- see "Lessons learned").
- IAM user `terraform-deployer`, scoped to only what this project needs (confirmed indirectly: the AWS Console "Cost and usage" and "AWS Health" widgets return `Access denied` for this user, which is the expected, intended behavior of a least-privilege deployment identity).

## 3. Findings generated

### Synthetic sample findings
Running `scripts/simulate_findings.sh <detector-id>` called the GuardDuty `CreateSampleFindings` API, generating 435 findings covering the full range of GuardDuty finding types, including:

- `PrivilegeEscalation:Runtime/CGroupsReleaseAgentModified` -- container escape via cgroups (High)
- `CredentialAccess:RDS/AnomalousBehavior.SuccessfulLogin` -- anomalous RDS login (High)
- `Trojan:Runtime/DropPoint` -- EC2 instance communicating with a drop point (Medium)
- `Object:S3/MaliciousFile` -- S3 malware scan detecting an EICAR test file (High)
- `Discovery:RDS/TorIPCaller` -- Tor exit node probing an RDS database (Medium)
- `Persistence:Kubernetes/MaliciousIPCaller.Custom` -- Kubernetes API called from a threat-listed IP (High)
- `DefenseEvasion:EC2/UnusualDNSResolver` -- EC2 instance using an unusual DNS resolver (Medium)

### Real findings (not triggered intentionally)

Two genuine findings were generated as a side effect of setting up AWS Console access for this project, and are more convincing evidence that the pipeline works than the synthetic samples:

**1. `TTPs/PenTest:IAMUser/KaliLinux` (Medium)** -- "The API CreateLoginProfile was invoked from a Kali Linux computer." GuardDuty correctly fingerprinted the source of the `aws iam create-login-profile` command (run from my own Kali Linux machine, public IP geolocated to Oslo, Norway, via Telia Norge AS) as a penetration-testing distribution.

**2. `AttackSequence:IAM/CompromisedCredentials` (Critical)** -- "Potential credential compromise of IAMUser/terraform-deployer indicated by a sequence of actions." This is a correlated, multi-signal finding (Security Hub's extended threat detection), not a single-event alert:

- Observed for `IAMUser/terraform-deployer`, principal ID `AIDA2TE7ERV4VYAO5IC6H`, account `728330702201`
- Time window: `2026-09-10T08:43:22Z` to `2026-09-10T09:00:39Z`
- 2 signals, 2 resources involved
- 3 MITRE ATT&CK tactics observed: Persistence, Discovery, Initial Access
- 4 MITRE ATT&CK techniques observed:
  - T1098.001 -- Account Manipulation: Additional Cloud Credentials
  - T1078.004 -- Valid Accounts: Cloud Accounts
  - T1087.004 -- Account Discovery: Cloud Account
  - T1526 -- Cloud Service Discovery

In this case the underlying activity (setting a console password and logging in via `terraform-deployer`) was legitimate and expected. Correctly recognizing that requires knowing the context behind the alert, which is exactly the kind of triage judgment a SOC analyst has to apply day to day -- a real finding isn't automatically a real incident.

## 4. Alerting pipeline verification

**Bug found and fixed:** the `aws_sns_topic_subscription.email` resource in `modules/alerting/main.tf` is conditional on `var.alert_email != ""`, and the `dev` environment never set this variable, so it defaulted to `""` and no subscription -- not even a pending one -- was ever created. `aws sns list-subscriptions-by-topic` confirmed an empty subscription list. Fixed by adding `terraform.tfvars` with `alert_email = "bobbysh14@gmail.com"` and re-applying, which created the subscription. The resulting SNS confirmation email initially landed in spam and had to be manually confirmed via the "Confirm subscription" link before any real alerts could be delivered.

TODO: once the alert email from the 2nd `simulate_findings.sh` run arrives, note here how long it took from generation to delivery, and whether it came from the GuardDuty rule, the Security Hub rule, or both.

## 5. Security Hub CIS 3.0 standard results

TODO: once Security Hub has had time to run its checks (can take a few hours on a freshly enabled account), note the initial compliance score here. Also worth noting: the original plan (and this file's own earlier template) assumed CIS AWS Foundations Benchmark **v2.0.0**, but `aws securityhub describe-standards --region eu-north-1` showed that version does not exist for this account/region -- only v1.2.0, v1.4.0, v3.0.0 and v5.0.0 are available. Switched to v3.0.0.

## 6. Lessons learned

- The `SubscriptionRequiredException` blocker that stalled deployment for a while turned out to be an AWS account-level restriction requiring an AWS Support case, not a bug in the Terraform code.
- A hardcoded standards ARN (`cis-aws-foundations-benchmark/v/2.0.0`) silently failed with `InvalidInputException` because that specific version isn't offered in every region/account. Worth checking `aws securityhub describe-standards` rather than assuming a version is universally available.
- A Terraform resource gated behind `count = var.x != "" ? 1 : 0` is easy to silently skip if the variable is never set anywhere -- `terraform plan`/`apply` doesn't warn about it, since "0 resources" is a valid, intentional configuration. Worth double-checking conditionally-created resources actually got created, not just that `apply` succeeded.
- GuardDuty/Security Hub correctly flagged legitimate administrative activity (setting an IAM console password from a pentesting-distro fingerprint) as a Critical correlated finding. In a real production account this would need tuning (suppression rules, allow-listing known admin workflows) to avoid alert fatigue -- otherwise genuine alerts get lost in noise from routine ops work.
- AWS's Security Hub console UI changed significantly (a new "Security Hub CSPM"/"Posture management" experience alongside the classic one) partway through this project, which made navigating to the same information inconsistent between sessions -- a reminder that console screenshots in documentation age faster than CLI-based verification (`aws securityhub describe-hub`, `get-findings`) does.

## License

MIT -- see [LICENSE](LICENSE).
