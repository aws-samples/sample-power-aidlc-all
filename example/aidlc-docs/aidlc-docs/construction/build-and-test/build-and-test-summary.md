# Build and Test Summary

> AI-DLC Construction artifact (Chapter 8.5). The Bolt advances only on a passing
> build-and-test gate, including the human-reviewed BMS boundary result on
> hardware. This summary becomes part of the evidence trail.

```text
Build: Success
Unit tests:         142 passed / 0 failed    coverage 88%
Integration tests:   18 passed / 0 failed    (schedule-api <-> charge-mgmt)
Contract tests:       6 passed / 0 failed    (ara::com, REST)
Security tests:       mTLS + auth verified; no high/critical findings
BMS boundary (HIL):   inhibit honored; safe-idle on link loss   [human-reviewed]
Ready for Operations: Yes
```

## How the numbers map to this repo
The book reports the full program totals (142 unit tests across all units). This
runnable example ships a representative, executable subset that demonstrates the
same gate. To reproduce locally:

| Tier | Unit | Command | What it verifies |
|---|---|---|---|
| Cloud | U2 tariff-planner | `python3 -m unittest discover -s tests` | CS-FR-014, CS-NFR-009 |
| Cloud | U1 schedule-api | `python3 -m unittest discover -s tests` | CS-SEC-005 auth+integrity, CS-FR-030 |
| Vehicle | U3 charge-management-service | `ctest --test-dir build` | CS-FR-014/021/030, status events |
| Vehicle (safety) | U4 bms-interface-adapter | `ctest --test-dir build` | CS-SR-002/003 (HIL stands in via tests) |
| Cloud+vehicle | U5 ota-delivery | `python3 -m unittest discover -s tests` | R156 baseline, rollback |
| Vehicle->cloud | U6 telemetry-feedback | `python3 -m unittest discover -s tests` | privacy minimization, monitoring metrics |

See `code/run_all_tests.sh` to run every unit's tests in one pass.

## Gate criteria (from NFR artifacts, Chapter 9)
- Functional: target SoC by departure; cached plan offline execution.
- Safety: inhibit honored immediately; safe-idle on interface loss (engineer-owned,
  HIL on real hardware; modeled here by U4's safety tests).
- Security: authenticated, integrity-protected commands (CS-SEC-005).
- Only a green summary — including the human-reviewed BMS boundary result — lets
  the feature proceed to Operations.

## Safety-requirement verification (Chapter 12.2)
The same gate records the safety-requirement results and SOTIF scenarios that the
safety case draws on end to end:

```text
Safety-requirement verification:
  CS-SR-002  inhibit honored immediately     BMS boundary (HIL)  [human-reviewed]  PASS
  CS-SR-003  safe-idle on interface loss      BMS boundary (HIL)  [human-reviewed]  PASS
SOTIF scenarios:
  cold-ambient early-inhibit                  scenario suite                        PASS
  stale tariff data -> safe default window    scenario suite                        PASS
```

## Brownfield variant (Chapter 14.4)
When the same feature is added into an existing estate rather than built
greenfield, the gate additionally runs the legacy regression suite and a
change-impact check, and confirms the frozen BMS boundary is unchanged:

```text
# Build and Test Summary (brownfield)

New feature tests:    58 passed / 0 failed
Regression (legacy): 431 passed / 0 failed   <- no disturbance to existing behavior
Change-impact:       telematics command_router + 1 ARXML intf; no other ECUs affected
BMS boundary (HIL):  inhibit honored; bms-control unmodified   [human-reviewed]
```
