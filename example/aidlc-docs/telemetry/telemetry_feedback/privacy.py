"""Privacy minimization at the vehicle boundary (U6).

Inception flagged location/usage data as privacy-sensitive. The design specifies
what is collected, minimized, and retained (Chapter 6.3 / 12.3). This function
runs on the vehicle side, before telemetry leaves the car:

  - the raw vehicle_id is replaced by a salted pseudonymous hash
  - precise location is dropped (we only need ambient temperature and outcomes)

The aggregator never sees the raw identifier or location.
"""

from __future__ import annotations

import hashlib

from .events import ChargeSessionRecord


def _pseudonymize(vehicle_id: str, salt: str) -> str:
    digest = hashlib.sha256((salt + ":" + vehicle_id).encode()).hexdigest()
    return "veh_" + digest[:16]


def minimize(record: ChargeSessionRecord, salt: str) -> ChargeSessionRecord:
    """Return a privacy-minimized copy safe to send to the fleet pipeline."""
    return ChargeSessionRecord(
        session_id=record.session_id,
        vehicle_id=_pseudonymize(record.vehicle_id, salt),
        reached_target=record.reached_target,
        departure_met=record.departure_met,
        cost_savings_pct=record.cost_savings_pct,
        early_inhibit=record.early_inhibit,
        ambient_c=record.ambient_c,
        safe_idle_regression=record.safe_idle_regression,
        location=None,  # dropped: not needed downstream
    )
