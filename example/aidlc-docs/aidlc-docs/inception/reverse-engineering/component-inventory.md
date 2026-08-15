# Component Inventory — Existing Vehicle Platform

> AI-DLC Inception artifact (Chapter 14.2). Every existing package classified,
> with its brownfield disposition for the charge-scheduling change.

## Application Components
- `telematics-gateway` — connectivity + command routing (Adaptive) — **modify in place**
- `bms-control` — cell/thermal protection (Classic, ASIL-C) — **frozen**
- `hvac-controller` — cabin thermal (Adaptive) — reuse (consume CabinThermal)

## Platform / Foundation
- `connectivity-mgr` — network selection/session — reuse
- `secure-storage` — keys and certificates — reuse

## Infrastructure Components
- `ota-campaign-service` — R156 staged rollout + rollback — reuse (new payload)
- `fleet-mqtt-broker` — command/telemetry transport — reuse
- `fleet-management-apis` — cloud backend — new service deploys beside these

## Test Assets (existing)
- Legacy regression suites per ECU (run as the brownfield regression gate, Ch 13.4)
- HIL benches for safety ECUs (used to confirm the frozen BMS boundary is intact)

## Count (existing estate, abridged)
- **Application**: 3    **Platform**: 2    **Infrastructure**: 3
- **Frozen (do-not-modify)**: 1  (`bms-control`)
- **Modify-in-place for this change**: 1  (`telematics-gateway`)
