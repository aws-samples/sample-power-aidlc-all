# API Documentation — Existing Vehicle Platform

> AI-DLC Inception artifact (Chapter 14.2). Recovers the existing interfaces the
> new feature consumes or extends. `BmsChargeControl` is consumed unchanged.

## In-vehicle interfaces (ara::com / SOME/IP)
### BmsChargeControl   (bms-control — certified, consume unchanged)
- `getPermittedEnvelope() -> {maxCurrent, maxVoltage, tempOk}`
- `isInhibited() -> bool`   (authoritative; may become true at any time)
- Event: `InhibitChanged`   (pushed when protection state changes)
- **Rule:** consumers may read and must obey; none may modify or suppress inhibit.

### CabinThermal   (hvac-controller)
- `setPreconditionTarget(setpoint, readyBy)`
- `getStatus() -> {cabinTemp, state}`

### CommandRouter   (telematics-gateway — modify in place)
- Existing: routes `{fleetCmd}` messages to registered services.
- Change (US-11): register and route `scheduleCmd` to charge-management-service.

## Cloud interfaces (existing)
### Fleet MQTT
- Topic `vehicle/{vin}/cmd` — signed commands to the vehicle.
- Topic `vehicle/{vin}/telemetry` — status and metrics from the vehicle.

### OTA Campaign Service (R156)
- `createCampaign(manifest)` / `advanceStage()` / `rollback(version)`

## Data Models (existing, relevant)
- **Command envelope**: `{id, vin, type, payload, sig}` (integrity-protected).
- **OTA manifest**: version, target components, dependencies, rollback target.
