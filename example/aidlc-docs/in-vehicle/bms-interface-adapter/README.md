# U4 — bms-interface-adapter (in-vehicle, SAFETY-RELEVANT)

The single, isolated path between the QM charge-management service (U3) and the
safety-relevant BMS. This is the bright line of Chapters 8-9: **none of this code
is AI-generated** — it is human-engineered, reviewed, and HIL-verified.

Satisfies CS-SR-002 (BMS limits authoritative; inhibit honored) and CS-SR-003
(loss of interface -> safe idle), with a hard real-time staleness deadline.
Story US-11.

## Components
- `safety_monitor` — watches inhibit + link health; latches unsafe; enforces the
  staleness deadline (WCET budget). Recovery only via explicit `Reset()`.
- `bms_interface_adapter` — surfaces a fail-safe `BmsEnvelope`; clamps any charge
  request to the BMS-permitted envelope; commands stop on any unsafe verdict.
- `IBmsLink` — abstract transport to the BMS (CAN/Ethernet/SOME/IP on target).

## Build & test
```
cmake -S . -B build
cmake --build build
ctest --test-dir build --output-on-failure
```

## Relationship to U3
U3's `BmsClient` is a thin fail-safe facade that adapts this unit to U3's
`IBmsAdapter` contract. The contract is intentionally narrow so the safety
surface stays small and reviewable (bulkhead pattern, NFR design).
