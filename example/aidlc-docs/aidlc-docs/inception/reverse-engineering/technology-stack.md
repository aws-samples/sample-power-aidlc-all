# Technology Stack — Existing Vehicle Platform

> AI-DLC Inception artifact (Chapter 14.2). The languages, frameworks, and
> toolchains already in the vehicle — the constraints any brownfield change works
> within.

## Programming Languages
- C++ (14/17) — AUTOSAR Adaptive applications (telematics, hvac)
- C — AUTOSAR Classic ECUs (bms-control; safety-critical)
- Python (3.x) — cloud fleet services

## Frameworks / Middleware
- AUTOSAR Adaptive — POSIX-based; `ara::com` service-oriented communication
- AUTOSAR Classic — deeply real-time, safety-critical ECU platform
- SOME/IP over Automotive Ethernet; CAN for legacy signals

## Infrastructure
- Fleet MQTT broker; OTA campaign service (UNECE R156)
- Cloud fleet-management backend; telemetry ingestion

## Build Tools
- CMake + vendor AUTOSAR Adaptive toolchain (vehicle apps)
- Vendor AUTOSAR Classic toolchain + ARXML (safety ECUs)
- pip + infrastructure-as-code (CDK) for cloud services

## Notes for AI-DLC (from Chapter 4 maturity gradient)
- Cloud + Adaptive service layers are strong generation candidates.
- Classic BSW is proprietary and MCU-coupled — no AI generation path; out of scope.
- Configuration (ARXML) is code and must be edited in place, not duplicated.
