# Personas — EV Charge Scheduling

> AI-DLC Inception artifact (Chapter 6.1). In an SDV the "user" can be a person,
> the vehicle itself, a background service, or a fleet operator.

## Commuter EV owner
- **Goal:** Leave each morning with a charged, comfortable car at the lowest cost.
- **Context:** Charges overnight at home; sets a departure time from a mobile app.
- **Pains:** Range anxiety, surprise energy bills, cold cabin on winter mornings.
- **Success:** Target SoC reached by departure; clear reason when it cannot be.
- **Related stories:** US-03, US-15

## Vehicle (autonomous actor)
- **Goal:** Execute the agreed plan safely, with or without connectivity.
- **Context:** In-vehicle charge-management service on AUTOSAR Adaptive; talks to
  the BMS only through the isolated adapter.
- **Pains:** Lost connectivity, stale plans, conflicting commands.
- **Success:** Cached plan runs locally; BMS inhibit always honored; safe idle on
  interface loss.
- **Related stories:** US-11

## Fleet operations manager
- **Goal:** Minimize aggregate energy cost across many vehicles.
- **Context:** Operates a fleet that charges on shared tariffs / demand-response.
- **Pains:** Peak-rate charging, uncoordinated load, opaque costs.
- **Success:** Charging shifted into off-peak windows without missing departures.
- **Related stories:** US-07
