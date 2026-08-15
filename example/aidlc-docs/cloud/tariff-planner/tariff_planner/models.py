"""Domain models for the tariff planner (U2)."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import List


@dataclass
class TariffWindow:
    """A time window with an energy price (cheaper = preferred)."""

    start_epoch_s: int
    end_epoch_s: int
    price_per_kwh: float

    def duration_min(self) -> int:
        return max(0, (self.end_epoch_s - self.start_epoch_s) // 60)


@dataclass
class PlanRequest:
    """Inputs to a planning run, from the schedule API (U1)."""

    vehicle_id: str
    current_soc_pct: int
    target_soc_pct: int
    departure_epoch_s: int
    battery_capacity_kwh: float = 60.0
    charge_power_kw: float = 11.0
    precondition_window_min: int = 20
    source: str = "APP"  # APP | RECURRING | DEMAND_RESPONSE (CS-FR-030)


@dataclass
class ChargeWindow:
    """A resolved window during which the vehicle should charge."""

    start_epoch_s: int
    end_epoch_s: int


@dataclass
class ChargePlan:
    """The resolved plan delivered to the vehicle and cached locally."""

    plan_id: str
    vehicle_id: str
    target_soc_pct: int
    departure_epoch_s: int
    precondition_window_min: int
    charge_windows: List[ChargeWindow] = field(default_factory=list)
    issued_at_epoch_s: int = 0
    source: str = "APP"
    estimated_minutes: int = 0
    estimated_cost: float = 0.0
    fallback: bool = False  # True when tariff data was unusable; safe default used

    def to_dict(self) -> dict:
        return {
            "plan_id": self.plan_id,
            "vehicle_id": self.vehicle_id,
            "target_soc_pct": self.target_soc_pct,
            "departure_epoch_s": self.departure_epoch_s,
            "precondition_window_min": self.precondition_window_min,
            "charge_windows": [
                {"start_epoch_s": w.start_epoch_s, "end_epoch_s": w.end_epoch_s}
                for w in self.charge_windows
            ],
            "issued_at_epoch_s": self.issued_at_epoch_s,
            "source": self.source,
            "estimated_minutes": self.estimated_minutes,
            "estimated_cost": round(self.estimated_cost, 4),
            "fallback": self.fallback,
        }
