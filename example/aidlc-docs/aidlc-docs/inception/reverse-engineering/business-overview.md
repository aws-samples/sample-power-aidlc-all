# Business Overview — Existing Vehicle Platform

> AI-DLC Inception artifact (Chapter 14.2). Recovers the business the existing SDV
> estate implements, so a brownfield change can be grounded in real transactions.

## Business Description
A connected EV platform delivering vehicle software features over the air to a
fleet, on consolidated in-vehicle compute, with a certified battery-protection
core. Value is added continuously through OTA-delivered features; the platform
must keep safety and update obligations intact across every release.

## Business Transactions (existing)
- **Connect & authenticate vehicle** — device identity, mTLS session to cloud.
- **Deliver command to vehicle** — cloud publishes; telematics routes to a service.
- **Protect the battery** — bms-control enforces thermal/cell limits, autonomously.
- **Manage cabin climate** — hvac-controller drives cabin thermal setpoints.
- **Deploy a software update** — R156 campaign packages, stages, and can roll back.
- **Ingest fleet telemetry** — vehicles report status; cloud aggregates.

## Business Dictionary
- **SoC** — battery state of charge.
- **Inhibit** — an authoritative BMS signal that charging must not proceed.
- **Campaign** — a governed, staged OTA rollout (canary → phased → fleet).
- **Envelope** — the charging parameters the BMS currently permits.

## Where charge scheduling fits
The new feature is a *consumer* of existing transactions: it reuses connect,
deliver-command, and deploy-update, and it must honor protect-the-battery without
modifying it. It adds one new transaction — **schedule a charge to a departure
time** — realized by units U1-U6.
