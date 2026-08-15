# Release Record — charge-management-service v1.3.0

> AI-DLC Operations artifact (Chapter 10.1). OTA deployment is a human-gated,
> staged rollout. AI proposes the strategy and assembles the evidence; a person
> signs.

```text
Gate:      Quality Steward sign-off  [human]   build-and-test-summary: PASS
Rollout:   canary 1% -> phased 25% -> fleet 100%   (halt on KPI breach)
Rollback:  proven; previous version v1.2.4 retained on-vehicle
Traces to: requirements CS-FR-014/021, CS-SR-002/003, CS-SEC-005
R156:      every VIN's deployed version recorded with this requirement baseline
```

## Rollout execution (modeled by U5)
The `ota/` unit (`RolloutController`) implements exactly this gate:
- `sign_off("Quality Steward")` must be called before `start()` — the human gate.
- The package refuses to construct without a `previous_version`, so rollback is
  always possible.
- `advance(kpi)` progresses CANARY -> PHASED -> FLEET only while readiness KPIs
  hold and there are zero safety regressions; otherwise it rolls back to v1.2.4.

## Requirement baseline (R156)
```text
component:        charge-management-service
version:          1.3.0
previous_version: 1.2.4
requirement_baseline: [CS-FR-014, CS-FR-021, CS-SR-002, CS-SR-003, CS-SEC-005]
artifact:         signed (HMAC/SHA-256 in the example; code-signing in production)
```
