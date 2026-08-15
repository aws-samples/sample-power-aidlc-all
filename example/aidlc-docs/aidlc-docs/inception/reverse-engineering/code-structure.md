# Code Structure — Existing Vehicle Platform

> AI-DLC Inception artifact (Chapter 14.2). The Existing Files Inventory names the
> files a brownfield change may touch — the basis for change-impact analysis and
> the modify-in-place discipline in Chapter 14.4.

## Build System
- **Vehicle (Adaptive apps)**: CMake + vendor AUTOSAR Adaptive toolchain
- **Vehicle (Classic ECUs)**: vendor AUTOSAR Classic toolchain; ARXML configuration
- **Cloud services**: Python (pip) + infrastructure-as-code (CDK)
- **Configuration is code**: much integration lives in ARXML and toolchain config,
  not `.cpp` — a modify step often edits configuration.

## Module Hierarchy (existing, abridged)
- `telematics/`  — connectivity gateway, command routing (Adaptive)
- `bms/`         — certified cell/thermal protection (Classic, ASIL-C)
- `hvac/`        — cabin thermal control (Adaptive)
- `platform/`    — connectivity-mgr, secure-storage (Adaptive foundation)
- `ota/`         — R156 campaign packaging and manifests
- `cloud/`       — fleet APIs, MQTT broker integration

### Existing Files Inventory   (candidates for modification)
- telematics/src/command_router.cpp   - routes cloud commands to services
- telematics/cfg/SomeIpServiceIntf.arxml - service interface config (config = code)
- bms/src/bms_control.c                - certified control loop  [FROZEN / review-gate]
- ota/campaign/manifest_schema.json    - R156 update manifest

## Design Patterns (observed)
- **Service-oriented (SOME/IP)**: components expose `ara::com` interfaces.
- **Command router**: single ingress for cloud-originated commands in telematics.
- **Authoritative safety monitor**: bms-control can inhibit independently of any
  requesting service — the pattern the new feature must respect, never override.

## Critical Dependencies (existing)
- `ara::com` middleware — service discovery and communication (Adaptive).
- Vendor BSW (basic software) for Classic ECUs — proprietary, MCU-coupled.
- Cloud MQTT client library — connectivity to the fleet broker.

## Brownfield disposition (for the charge-scheduling change)
| File / area | Disposition |
|---|---|
| telematics/src/command_router.cpp | Modify in place (route schedule commands) |
| telematics/cfg/SomeIpServiceIntf.arxml | Modify in place (add service interface) |
| bms/src/bms_control.c | **Frozen** — certified, do not modify |
| ota/campaign/manifest_schema.json | Reuse (R156 baseline for the new payload) |
