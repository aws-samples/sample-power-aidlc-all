# U1 — schedule-api (cloud)

Driver-facing, authenticated REST API. Accepts a departure time / target SoC,
calls the tariff planner (U2), stores the resolved plan, signs the
cloud-to-vehicle command, and exposes status. QM-rated; security-sensitive.

Traces to: US-03, US-15, CS-SEC-005, CS-FR-030. Depends on U2 (tariff-planner).

## Security (CS-SEC-005, Security Baseline extension)
The API is network-exposed, so authentication is a design requirement, not later
hardening. Every request requires `Authorization: Bearer <token>`, and each
cloud-to-vehicle plan carries an HMAC integrity signature. In production these
stand-ins are replaced by mTLS + IAM-scoped credentials (infrastructure-design.md).

## Run
```
python3 -m unittest discover -s tests -p 'test_*.py' -v   # tests
python3 main.py                                            # local server :8080
```

## Routes
```
POST /v1/schedules                set/replace a schedule (US-03)
GET  /v1/schedules/{vehicle_id}   vehicle pulls its resolved plan
POST /v1/status                   vehicle reports status (US-15)
GET  /v1/status/{vehicle_id}      app reads status
GET  /healthz                     liveness (unauthenticated)
```
Standard-library only (`http.server`); no web framework required to run the demo.
