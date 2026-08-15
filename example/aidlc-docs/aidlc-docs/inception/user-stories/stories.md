# User Stories — EV Charge Scheduling

> AI-DLC Inception artifact (Chapter 6.1). INVEST-structured. Each story keeps a
> link back to its source requirement so the traceability chain extends rather
> than restarts. Stories sit at three altitudes: driver-facing, vehicle-internal,
> and backend/fleet.

## US-03 — Departure-time charging (driver)
As a driver, I want to set a departure time from my app so that my car is
charged to my target SoC and pre-conditioned when I leave.

Acceptance criteria:
- Given the car is plugged in with grid power, when a departure time is set,
  then the battery reaches the target SoC no later than that time.
- Given the target cannot be met (short plug-in time / grid fault),
  then the driver is notified with the reason.

Traces to: CS-FR-014, CS-NFR-007   |   Persona: Commuter EV owner

## US-07 — Off-peak cost optimization (fleet operator)
As a fleet operator, I want vehicles to charge during off-peak windows so that
energy cost across the fleet is minimized.

Acceptance criteria:
- Given tariff windows are available, when a plan is computed, then charging is
  scheduled into the cheapest windows that still meet the departure deadline.
- Given tariff data is stale or missing, then the planner uses a safe default
  window and the vehicle still reaches target SoC by departure.

Traces to: CS-FR-014, CS-FR-030   |   Persona: Fleet operations manager

## US-11 — Offline schedule execution (charge-management service)
As the charge-management service, I need to execute the most recent schedule
even with no connectivity so that charging is reliable off-grid.

Acceptance criteria:
- Given a cached plan exists, when connectivity is lost, then the plan executes
  locally without any cloud dependency.
- Given no cached plan exists, then the service falls back to immediate charge
  within the BMS-permitted envelope.
- In all cases, a BMS inhibit stops charge initiation immediately and is never
  overridden.

Traces to: CS-FR-021, CS-SR-002, CS-SR-003   |   Persona: Vehicle (autonomous actor)

## US-15 — Charge status feedback (driver)
As a driver, I want to see whether my car is on-track, delayed, complete, or in a
fault state so that I can react before I leave.

Acceptance criteria:
- Given a plan is executing, then status updates flow back to the app.
- Given a fault occurs, then the reason is reported in plain language.

Traces to: CS-FR-031   |   Persona: Commuter EV owner

## Story map (altitude)
- Driver-facing:    US-03, US-15
- Backend/fleet:    US-07
- Vehicle-internal: US-11   (crosses the safety boundary -> inherits CS-SR-*)
