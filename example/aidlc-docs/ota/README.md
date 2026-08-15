# U5 — ota-delivery (cloud + vehicle)

Packages and signs the in-vehicle component, binds every version to the R156
requirement baseline it satisfies, and drives a human-gated staged rollout
(canary -> phased -> fleet) with first-class rollback. QM-rated; release-governed.

Traces to: OTA intent, UNECE R156. See operations/release-record.md.

## Run tests
```
python3 -m unittest discover -s tests -p 'test_*.py' -v
```

## Key ideas
- `packager.build_package` records `requirement_baseline` (R156 traceability) and
  signs the manifest; `verify_package` checks artifact digest + signature.
- `rollout.RolloutController` refuses to start without a human `sign_off` and
  without a `previous_version` (so rollback is always possible). It rolls back on
  a readiness-KPI breach or any safety regression.
