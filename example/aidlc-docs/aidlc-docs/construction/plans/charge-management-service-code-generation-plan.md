# Code-Generation Plan — charge-management-service

> AI-DLC Construction artifact (Chapter 8.2). Numbered, story-traced, per-unit
> plan the team approves before generation. Application code lands in the
> workspace; this tree keeps the markdown summary.

Target: in-vehicle/charge-management-service/   (AUTOSAR Adaptive app)
Stories: US-03, US-11    Depends on: bms-interface-adapter (U4)

[x] Step 1  Business logic — schedule execution & SoC tracking
[x] Step 2  Business logic unit tests
[x] Step 3  ara::com service interface (from IDL)
[ ] Step 4  BMS adapter client (honor inhibit; safe idle)   <- review-gated
[ ] Step 5  Telemetry/status publisher
[ ] Step 6  Deployment artifacts + manifest

> Checkbox state above reproduces the Chapter 8 snapshot (steps 1-3 generated,
> 4-6 pending — the review-gated boundary last). Completion of all steps is
> recorded in `../charge-management-service/code/charge-management-service-summary.md`
> and confirmed by the build-and-test gate.

## Per-step notes
- Steps 1-3, 5-6: AI-generated QM code, CI-verified, reviewed via pull request.
- Step 4: scaffolded against the agreed interface contract, but the logic that
  honors a BMS inhibit is safety-relevant and is human-engineered and reviewed
  (the boundary `bms_client.cpp`). AI assists with structure only.
- Tests are generated alongside code (Chapter 8.4); safety-constraint tests
  (CS-SR-002) are written and reviewed by engineers.
