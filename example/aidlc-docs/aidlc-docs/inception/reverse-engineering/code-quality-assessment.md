# Code Quality Assessment — Existing Vehicle Platform

> AI-DLC Inception artifact (Chapter 14.2). A candid read of the existing estate,
> so the brownfield change knows what it is building on.

## Test Coverage
- **Overall**: Fair — good on safety ECUs, uneven on the telematics layer.
- **Unit Tests**: Present for bms-control (certification evidence) and hvac.
- **Integration Tests**: Partial for the telematics command path.
- **Regression suites**: Maintained per ECU; run as the brownfield regression gate.

## Code Quality Indicators
- **Linting**: MISRA checks enforced on Classic C (bms-control); lighter on Adaptive C++.
- **Code Style**: Consistent within each supplier package; varies across packages.
- **Documentation**: Good for certified components; sparse for the telematics gateway.

## Technical Debt
- `command_router.cpp` has grown organically; routing is a long conditional that
  would benefit from a registration table (in-scope, low-risk refactor when U3 is added).
- ARXML service interfaces are hand-maintained; easy to drift from code.

## Patterns and Anti-patterns
- **Good patterns**: authoritative safety monitor (bms-control); mTLS everywhere;
  governed R156 campaigns.
- **Anti-patterns to avoid inheriting**: duplicated command handlers across older
  services (do not add a `command_router_v2.cpp` — modify in place, Chapter 14.4).

## Readiness for a brownfield change
- Cloud + Adaptive telematics layer: safe to modify in place with regression gating.
- bms-control: **do not modify** — consume `BmsChargeControl` unchanged; HIL confirms
  the boundary is undisturbed.
