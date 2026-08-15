# U3 — charge-management-service (in-vehicle)

AUTOSAR Adaptive-style C++ service that executes the cached charge plan within
the BMS-permitted envelope. QM-rated, mostly AI-generated; the BMS boundary
client (`bms_client.cpp`) is safety-relevant and human-engineered (review-gated).

Traces to: CS-FR-014, CS-FR-021, CS-FR-030, CS-FR-031 (and inherits CS-SR-002/003
through the boundary). Stories US-03, US-11.

## Layout
```
include/charge_management/   public headers (domain, interfaces)
src/                         implementation
  bms_client.cpp             SAFETY-RELEVANT boundary (review-gated)
  schedule_executor.cpp      QM state machine (BR-01..05)
  soc_tracker.cpp            charge-time estimation
  telemetry_publisher.cpp    status events (-> U6)
  main.cpp                   demo service application
tests/                       unit tests (CTest)
manifest/                    deployment manifest (ARXML modeled as JSON)
```

## Build & test
```
cmake -S . -B build
cmake --build build
ctest --test-dir build --output-on-failure
./build/charge_management_service   # demo simulation
```

Requires CMake >= 3.16 and a C++17 compiler. No AUTOSAR SDK needed — the
`ara::com` service interface and manifest are modeled in portable C++/JSON so the
example runs on a developer machine.

## Safety boundary
`bms_client.cpp` is the bright line of Chapters 8-9. It is a fail-safe facade:
any uncertainty (invalid read, interface loss, inhibit) is treated as a stop. The
real BMS adapter is Unit U4 (`../bms-interface-adapter`). Generative AI is never
on the BMS control path.
