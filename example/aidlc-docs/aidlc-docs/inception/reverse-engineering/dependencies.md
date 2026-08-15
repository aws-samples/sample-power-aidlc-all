# Dependencies — Existing Vehicle Platform

> AI-DLC Inception artifact (Chapter 14.2). Internal and external dependencies of
> the existing estate — the inputs to change-impact analysis (Chapter 14.4).

## Internal Dependencies (existing)
### telematics-gateway depends on connectivity-mgr, secure-storage
- **Type**: Runtime
- **Reason**: network sessions and credentials for cloud connectivity

### charge-management-service (new, U3) depends on telematics-gateway, bms-control
- **Type**: Runtime (consumes CommandRouter and BmsChargeControl)
- **Reason**: receives routed schedule commands; obeys the BMS envelope/inhibit

### bms-control depends on: none in this feature's scope
- **Type**: —
- **Reason**: authoritative and self-contained; **frozen**

## Change-impact note (schedule command path)
Modifying `command_router.cpp` and its ARXML interface affects only the telematics
service and the new charge-management-service. Consumers of other routed command
types are unaffected — confirmed against the SOME/IP interface map. No safety ECU
is touched.

## External Dependencies (existing)
### ara::com middleware
- **Purpose**: service discovery and communication (Adaptive)
- **License**: vendor-licensed

### MQTT client library
- **Purpose**: cloud broker connectivity
- **License**: open-source (permissive)

### Vendor BSW (Classic)
- **Purpose**: basic software for safety ECUs
- **License**: proprietary; no AI generation path
