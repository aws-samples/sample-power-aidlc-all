# U2 — tariff-planner (cloud)

Pure-Python charge-plan optimizer. Computes the minutes of charging needed to
reach target SoC and places them in the cheapest tariff windows before the
readiness deadline. Falls back to a safe default window when tariff data is
missing or stale. QM-rated.

Traces to: US-07, CS-FR-014, CS-FR-030, CS-NFR-009.

## Run tests
```
python3 -m unittest discover -s tests -p 'test_*.py' -v
```
No third-party dependencies. The module is pure (no I/O), so it is fully
unit-testable — the Accelerate band of Chapter 4 where AI-DLC generates and CI
verifies end to end.
