# System Architecture — Existing Vehicle Platform

> AI-DLC Inception artifact (Chapter 14.2). Reverse engineering reconstructs the
> existing SDV estate that EV charge scheduling is added *into* — it does not
> describe the new feature. The certified BMS control is surfaced here as a frozen
> safety boundary, not invented later. This is the Chapter 14 brownfield companion
> to the greenfield trail in the rest of `aidlc-docs/`.

## System Overview
A production EV platform combining AUTOSAR Classic safety ECUs, AUTOSAR
Adaptive high-performance compute, and a cloud fleet backend. Off-board
connectivity flows through a supplier telematics gateway; battery protection is
owned by a certified BMS ECU. The charge-scheduling feature (units U1-U6) reuses
this connectivity and consumes the BMS inhibit interface unchanged.

## Component Descriptions
### telematics-gateway   (existing, supplier v2.4)
- Purpose:      off-board connectivity; MQTT to cloud; command routing
- Dependencies: connectivity-mgr, secure-storage
- Type:         Application (AUTOSAR Adaptive)

### bms-control          (existing, ASIL-C, certified — DO NOT MODIFY)
- Purpose:      cell protection, thermal limits, charge inhibit (authoritative)
- Interface:    ara::com  BmsChargeControl  (inhibit, permitted-envelope)
- Type:         Application (AUTOSAR Classic; safety-critical)

### hvac-controller      (existing, supplier v1.9)
- Purpose:      cabin thermal management; reused for pre-conditioning
- Interface:    ara::com  CabinThermal  (setpoint, status)
- Type:         Application (AUTOSAR Adaptive)

### connectivity-mgr / secure-storage   (existing platform services)
- Purpose:      network selection and session management; key/certificate store
- Type:         Platform (AUTOSAR Adaptive foundation)

## Integration Points
- Vehicle bus:  CAN + Automotive Ethernet (SOME/IP)
- Cloud:        existing fleet MQTT broker; OTA campaign service (R156)
- Identity:     device certificates in secure-storage; mTLS to cloud

## Data Flow (charge command, existing path reused)
1. Cloud publishes a signed command to the fleet MQTT broker.
2. telematics-gateway receives and routes it via command_router.
3. The new charge-management-service (U3) consumes the routed command.
4. U3 requests charging strictly within the BmsChargeControl permitted envelope.
5. bms-control retains authority to inhibit at any time (unchanged).

## Infrastructure Components
- OTA:          existing R156 campaign service; manifest-driven staged rollout
- Cloud:        fleet management APIs; MQTT broker; telemetry ingestion
- Deployment:   Adaptive apps packaged as OTA payloads; Classic ECUs flashed via
                governed campaigns only (bms-control not in this feature's scope)
