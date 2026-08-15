# Business Logic Model — charge-management-service

> AI-DLC Construction artifact (Chapter 6.2 / 6.2). Technology-agnostic behavior:
> what the service does, in what order, under what conditions — before naming a
> protocol, OS, or cloud provider.

## Functional flow (technology-agnostic)
1. The driver submits a target SoC and departure time (via cloud API, U1).
2. The scheduler (cloud, U2) computes a charging plan from current SoC, tariff
   windows, and estimated charge time, leaving margin for pre-conditioning.
3. The plan is delivered to the vehicle and cached locally (plan-cache).
4. At the planned start, the charge-management service requests charging within
   the BMS-permitted envelope.
5. The service monitors progress and adjusts, but NEVER overrides a BMS inhibit.
6. Status (on-track, delayed, complete, fault) flows back to the driver (U6/U1).

## State model (charge session)
```text
IDLE ──plan due & plug present & grid power──▶ REQUESTING
REQUESTING ──BMS grants envelope──▶ CHARGING
CHARGING ──target SoC reached──▶ COMPLETE
CHARGING ──BMS inhibit──▶ SAFE_IDLE        (hard, immediate; BR-02)
any state ──BMS interface lost──▶ SAFE_IDLE (hard; BR-03)
SAFE_IDLE ──inhibit cleared & interface ok──▶ REQUESTING
```

## Inputs / outputs
- Inputs: resolved plan (target SoC, departure time, charge windows), current SoC,
  BMS envelope + inhibit signal, plug/grid status, ambient/cabin temperature.
- Outputs: charge request (within envelope), pre-condition request, status events.

## What this model deliberately does NOT decide
- Messaging protocol (SOME/IP vs DDS), OS, or cloud provider — those are
  Construction architecture decisions (Chapter 7).
- The BMS's internal thermal/cell protection control — out of scope, human-owned.
