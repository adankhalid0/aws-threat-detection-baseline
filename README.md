# AWS Threat Detection Baseline

A managed threat-detection and alerting layer for AWS — **GuardDuty** +
**Security Hub**, wired to a real notification pipeline with
**EventBridge** and **SNS**, deployed with **Terraform** and enforced
continuously with **GitHub Actions**.

> Companion project to
> [aws-cloud-security-baseline](https://github.com/adankhalid0/aws-cloud-security-baseline).
> That project builds and audits secure configuration. This one answers a
> different question: if something actively goes wrong in the account,
> does anyone find out?

## Why this project

A well-configured, well-audited AWS account (the companion project) can
still be compromised — a leaked credential, a misused role, an S3 bucket
someone made public by accident despite every guardrail. Configuration
auditing catches drift from a known-good state; it doesn't catch an
attacker doing something the configuration never anticipated. That's what
detection is for.

This project:

1. **Enables** GuardDuty (managed threat detection) and Security Hub
   (continuous CIS 2.0 compliance monitoring + finding aggregation).
2. **Builds** an EventBridge → SNS pipeline so findings actually reach an
   inbox instead of sitting unread in a console.
3. **Proves** the pipeline works end-to-end using GuardDuty's own
   supported sample-finding mechanism — no real attack simulation, no
   unnecessary risk to the account.
4. **Documents** what actually happened: timestamps, findings generated,
   whether and when the alert arrived.

See [`docs/PLAN.md`](docs/PLAN.md) for the full build plan, and
[`docs/DETECTION_FINDINGS.md`](docs/DETECTION_FINDINGS.md) for the
documented results of this specific run.

## Architecture

```
        ┌─────────────────────────────────────────────┐
        │                 AWS Account                   │
        │                                               │
        │   ┌────────────┐        ┌──────────────────┐  │
        │   │ GuardDuty  │        │  Security Hub     │  │
        │   │ (threat    │───────►│  (CIS 2.0 +       │  │
        │   │ detection) │findings│  finding          │  │
        │   └────────────┘        │  aggregation)     │  │
        │         │                └─────────┬─────────┘  │
        │         │ findings                  │ findings   │
        │         ▼                           ▼            │
        │   ┌─────────────────────────────────────────┐   │
        │   │            EventBridge rules              │   │
        │   │  (all GuardDuty · CRITICAL/HIGH SecHub)   │   │
        │   └───────────────────┬───────────────────────┘   │
        │                       ▼                            │
        │               ┌───────────────┐                    │
        │               │  SNS (KMS)    │──► email alert      │
        │               └───────────────┘                    │
        └─────────────────────────────────────────────┘
```

## What gets deployed

| Component | Purpose | Key details |
|-----------|---------|--------------|
| `modules/guardduty` | Managed threat detection | S3 data-event protection, 15-minute finding publishing frequency |
| `modules/security-hub` | Continuous compliance + finding aggregation | Subscribed to CIS AWS Foundations Benchmark 2.0 |
| `modules/alerting` | Findings → notification | EventBridge rules + KMS-encrypted SNS topic + email subscription |

## Tooling

- **Terraform** (>= 1.6) — Infrastructure as Code
- **Amazon GuardDuty** — managed threat detection
- **AWS Security Hub** — continuous compliance monitoring
- **Amazon EventBridge + SNS** — findings routing and alerting
- **Checkov** — static analysis of the Terraform code
- **GitHub Actions** — CI pipeline running `terraform fmt`, `terraform validate`, and Checkov on every push/PR

## Getting started

Full instructions with explanations: [`docs/PLAN.md`](docs/PLAN.md).
Quick version:

```bash
# 1. Fill in the backend block in terraform/environments/dev/versions.tf
#    with the state bucket/lock table from aws-cloud-security-baseline's
#    terraform/bootstrap (a different `key`, same backend infra).
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars   # edit with your values
terraform init
terraform plan
terraform apply

# 2. Scan the code with Checkov
cd ../../..
checkov -d terraform --config-file .checkov.yaml

# 3. Verify the alerting pipeline end-to-end
./scripts/simulate_findings.sh $(terraform -chdir=terraform/environments/dev output -raw guardduty_detector_id)

# 4. Check your inbox, then document what happened in
#    docs/DETECTION_FINDINGS.md
```

## Results

See [`docs/DETECTION_FINDINGS.md`](docs/DETECTION_FINDINGS.md) for the
full documented run — sample findings generated, whether they reached
Security Hub, and how long the alert email took to arrive.

## Cleanup

```bash
cd terraform/environments/dev && terraform destroy
```

## Lessons learned

_Short personal reflection — filled in after actually running this
against a live account: what surprised you, what you'd do differently in
production, anything the documentation didn't quite prepare you for._

## License

MIT — see [LICENSE](LICENSE).
