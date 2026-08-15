# DORA Snapshot — EV Charge Scheduling

> AI-DLC measurement artifact (Chapter 11.3). Derived from the documentation-first
> artifacts the earlier phases produced — `audit.md`, `build-and-test-summary.md`,
> `release-record.md`, and `monitoring-summary.md`. DORA is tracked *per layer*,
> not as a single fleet-wide number.

```text
# DORA Snapshot — EV charge scheduling (derived from aidlc-docs)
# sources: audit.md, build-and-test-summary.md, release-record.md, monitoring-summary.md

Unit: cloud-schedule-api          (Accelerate)
  Deployment frequency ...  on demand (multiple/week)
  Lead time for changes ...  hours  (commit -> cloud deploy)
  Change failure rate .....  low; contract tests + canary
  Recovery time ...........  minutes (automated rollback)

Unit: charge-management-service   (Pilot; in-vehicle)
  Deployment frequency ...  per OTA campaign (weeks)  <- bounded by fleet rollout
  Lead time for changes ...  days; HIL gate + human review of BMS boundary
  Change failure rate .....  low; staged canary -> phased -> fleet
  Recovery time ...........  staged rollback; per-VIN version pinning (R156)
```

## Reading the snapshot (Chapter 11.4)
- Read throughput (deployment frequency, lead time) and stability (change failure
  rate, recovery time) **as a pair** — a speed gain that raises failures is not a win.
- The cloud unit shows the headline gains; the in-vehicle unit shows modest,
  gate-protected gains; there is no throughput claim on the safety-critical
  control path.

## SDV guardrail metrics (not DORA; safety is never a DORA metric)
- Review latency and review backlog (is validation keeping up with generation?).
- Escaped-defect and field-anomaly rate (from monitoring-summary.md).
- Safety-gate and HIL pass rates, and any safety-relevant rollback.
- Security-finding rate from the Security Baseline checks (security-compliance.md).
