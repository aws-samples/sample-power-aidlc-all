"""U2 - tariff-optimization & planning (cloud).

Computes a charging plan that reaches the target SoC by departure while
preferring the cheapest off-peak tariff windows. Traces to US-07, CS-FR-014,
CS-FR-030. QM-rated; strong candidate for end-to-end AI-DLC generation.
"""

from .models import ChargePlan, ChargeWindow, PlanRequest, TariffWindow
from .planner import compute_plan, minutes_needed

__all__ = [
    "ChargePlan",
    "ChargeWindow",
    "PlanRequest",
    "TariffWindow",
    "compute_plan",
    "minutes_needed",
]
