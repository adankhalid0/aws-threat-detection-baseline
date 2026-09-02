# Project Plan

This document describes the approach and phased structure I followed to
build this project, along with recommendations for anyone attempting
something similar.

## Approach

This is the companion piece to my other portfolio project,
[aws-cloud-security-baseline](https://github.com/adankhalid0/aws-cloud-security-baseline).
That project is about configuration: building infrastructure securely and
auditing whether it stays that way. It doesn't answer a different
question that matters just as much in a real environment -- if something
is actively going wrong right now, does anyone find out?

This project answers that question. It enables Amazon GuardDuty (managed
threat detection) and AWS Security Hub (continuous compliance monitoring
and finding aggregation), wires their findings into an EventBridge ->
SNS pipeline so they actually reach an inbox, and then proves the
pipeline works end-to-end using GuardDuty's own supported sample-finding
mechanism -- no real attack simulation, no unnecessary risk to the
account.

## Phases

| Phase | Focus |
|---|---|
| 1 | Enable GuardDuty with S3 protection, and Security Hub with the CIS AWS Foundations Benchmark 2.0 standard |
| 2 | Build the EventBridge -> SNS alerting pipeline for GuardDuty and Security Hub findings |
| 3 | Deploy to the same AWS account used for aws-cloud-security-baseline, reusing its remote-state backend with a separate state key |
| 4 | Generate GuardDuty sample findings and confirm they reach Security Hub and the alert inbox |
| 5 | Document what actually happened -- timestamps, findings, whether the alert arrived and how long it took |
| 6 | Wire up GitHub Actions CI to run fmt/validate/Checkov on every push, same pattern as the companion project |

## Recommendations for anyone building something similar

- Detection is a different skill from prevention. A clean, well-audited
  account (the other project) says nothing about whether anyone would
  notice an actual compromise. Build both if you can -- they demonstrate
  different things.
- Use the vendor's own sample-finding mechanism to test alerting rather
  than trying to trigger a "real" finding yourself. It's safer, it's
  faster, and it's literally what the feature exists for.
- An enabled detector that nobody gets notified from is barely better
  than no detector -- the EventBridge -> SNS wiring is not optional
  plumbing, it's the actual point of the project.
- Filter what you alert on. Routing every Security Hub finding
  unfiltered would be noisy even in a tiny account; alerting only on
  CRITICAL/HIGH is a small decision worth explaining, not just making
  silently.
- Reuse infrastructure you already have (remote state, in this case)
  instead of duplicating it for a second small project. It's a more
  realistic decision than standing up parallel infrastructure for
  everything.
