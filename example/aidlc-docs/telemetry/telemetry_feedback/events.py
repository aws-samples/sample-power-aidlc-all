"""Telemetry event model (U6)."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Optional


@dataclass
class ChargeSessionRecord:
    """One completed charge session reported by a vehicle.

    Privacy note: `vehicle_id` and `location` are sensitive. They are present at
    the vehicle but MUST be minimized before leaving the car (see privacy.py).
    """

    session_id: str
    vehicle_id: str
    reached_target: bool          # did SoC reach target?
    departure_met: bool           # ready by departure? (readiness accuracy)
    cost_savings_pct: float       # vs. unscheduled charging
    early_inhibit: bool           # BMS inhibited earlier than expected
    ambient_c: float              # ambient temperature during the session
    safe_idle_regression: bool = False  # safety signal; must stay False
    location: Optional[str] = None      # precise location (sensitive)
