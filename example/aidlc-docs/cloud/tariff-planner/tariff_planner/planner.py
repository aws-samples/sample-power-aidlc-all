"""Charge-plan computation (U2).

Behavior (mirrors functional design, Chapter 5/6):
  - Compute the minutes of charging needed to reach target SoC.
  - Prefer the cheapest tariff windows before the readiness deadline.
  - If tariff data is missing or stale, fall back to a safe default window so the
    vehicle still reaches target SoC by departure (CS-FR-014, CS-NFR-009).
  - Safety/charge limits always win over cost (BR-04); cost only reorders work.

This module is pure (no I/O), so it is fully unit-testable.
"""

from __future__ import annotations

import math
from typing import List, Optional

from .models import ChargePlan, ChargeWindow, PlanRequest, TariffWindow


def minutes_needed(req: PlanRequest) -> int:
    """Minutes of charging to move from current to target SoC at charge_power_kw."""
    if req.target_soc_pct <= req.current_soc_pct:
        return 0
    if req.charge_power_kw <= 0 or req.battery_capacity_kwh <= 0:
        return 0
    soc_delta = (req.target_soc_pct - req.current_soc_pct) / 100.0
    energy_kwh = soc_delta * req.battery_capacity_kwh
    hours = energy_kwh / req.charge_power_kw
    return max(1, int(math.ceil(hours * 60.0)))


def _readiness_deadline(req: PlanRequest) -> int:
    """Latest moment charging must finish to leave room for pre-conditioning."""
    return req.departure_epoch_s - req.precondition_window_min * 60


def _tariff_is_usable(tariffs: Optional[List[TariffWindow]], now_epoch_s: int,
                      deadline_epoch_s: int) -> bool:
    if not tariffs:
        return False
    # Usable only if at least one window overlaps the [now, deadline] horizon.
    for w in tariffs:
        if w.end_epoch_s > now_epoch_s and w.start_epoch_s < deadline_epoch_s:
            return True
    return False


def _clip(window: TariffWindow, lo: int, hi: int) -> Optional[TariffWindow]:
    start = max(window.start_epoch_s, lo)
    end = min(window.end_epoch_s, hi)
    if end <= start:
        return None
    return TariffWindow(start, end, window.price_per_kwh)


def _merge(windows: List[ChargeWindow]) -> List[ChargeWindow]:
    """Sort by start and merge adjacent/overlapping windows."""
    if not windows:
        return []
    ordered = sorted(windows, key=lambda w: w.start_epoch_s)
    merged = [ordered[0]]
    for w in ordered[1:]:
        last = merged[-1]
        if w.start_epoch_s <= last.end_epoch_s:
            last.end_epoch_s = max(last.end_epoch_s, w.end_epoch_s)
        else:
            merged.append(w)
    return merged


def compute_plan(
    req: PlanRequest,
    tariffs: Optional[List[TariffWindow]],
    now_epoch_s: int,
    plan_id: str,
) -> ChargePlan:
    plan = ChargePlan(
        plan_id=plan_id,
        vehicle_id=req.vehicle_id,
        target_soc_pct=req.target_soc_pct,
        departure_epoch_s=req.departure_epoch_s,
        precondition_window_min=req.precondition_window_min,
        issued_at_epoch_s=now_epoch_s,
        source=req.source,
    )

    needed = minutes_needed(req)
    plan.estimated_minutes = needed
    if needed == 0:
        return plan  # already at/above target; nothing to schedule

    deadline = _readiness_deadline(req)
    price_per_min = req.charge_power_kw / 60.0  # kWh per minute at charge power

    if not _tariff_is_usable(tariffs, now_epoch_s, deadline):
        # Safe default (CS-NFR-009): charge in the final `needed` minutes before
        # the deadline, clamped to start no earlier than now.
        start = max(now_epoch_s, deadline - needed * 60)
        start = min(start, deadline)
        plan.charge_windows = [ChargeWindow(start, deadline)]
        plan.fallback = True
        plan.estimated_cost = 0.0  # unknown price under fallback
        return plan

    # Cost optimization: take the cheapest minutes first, within [now, deadline].
    clipped = []
    for w in tariffs:  # type: ignore[union-attr]
        c = _clip(w, now_epoch_s, deadline)
        if c is not None:
            clipped.append(c)
    clipped.sort(key=lambda w: (w.price_per_kwh, w.start_epoch_s))

    remaining = needed
    chosen: List[ChargeWindow] = []
    cost = 0.0
    for w in clipped:
        if remaining <= 0:
            break
        avail = w.duration_min()
        take = min(avail, remaining)
        if take <= 0:
            continue
        end = w.start_epoch_s + take * 60
        chosen.append(ChargeWindow(w.start_epoch_s, end))
        cost += take * price_per_min * w.price_per_kwh
        remaining -= take

    if remaining > 0:
        # Not enough cheap window time before the deadline: fill greedily right
        # up to the deadline (deadline pressure beats cost; BR-04) and flag it.
        start = max(now_epoch_s, deadline - remaining * 60)
        chosen.append(ChargeWindow(start, deadline))
        plan.fallback = True

    plan.charge_windows = _merge(chosen)
    plan.estimated_cost = cost
    return plan
