"""Schedule service logic (U1), independent of the HTTP transport so it is
fully unit-testable. The HTTP layer (app.py) is a thin shell over this.
"""

from __future__ import annotations

import os
import sys
import time
import uuid
from typing import Dict, List, Optional

from .auth import AuthError, TokenAuthenticator

# U1 -> U2: the API surfaces the planner (see unit-of-work.md dependency matrix).
sys.path.insert(
    0,
    os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "tariff-planner")),
)
from tariff_planner import PlanRequest, TariffWindow, compute_plan  # noqa: E402


class ScheduleService:
    def __init__(self, authenticator: TokenAuthenticator,
                 tariffs: Optional[List[TariffWindow]] = None,
                 clock=time.time):
        self._auth = authenticator
        self._tariffs = tariffs
        self._clock = clock
        self._plans: Dict[str, dict] = {}      # vehicle_id -> plan dict
        self._status: Dict[str, dict] = {}      # vehicle_id -> last status event

    # --- Driver-facing: create/replace a schedule (US-03) ---------------------
    def set_schedule(self, authorization: str, body: dict) -> dict:
        identity = self._auth.authenticate(authorization)  # CS-SEC-005

        try:
            req = PlanRequest(
                vehicle_id=str(body["vehicle_id"]),
                current_soc_pct=int(body.get("current_soc_pct", 50)),
                target_soc_pct=int(body["target_soc_pct"]),
                departure_epoch_s=int(body["departure_epoch_s"]),
                battery_capacity_kwh=float(body.get("battery_capacity_kwh", 60.0)),
                charge_power_kw=float(body.get("charge_power_kw", 11.0)),
                precondition_window_min=int(body.get("precondition_window_min", 20)),
                source=str(body.get("source", "APP")),
            )
        except (KeyError, ValueError, TypeError) as exc:
            raise ValueError(f"invalid schedule request: {exc}") from exc

        if not (0 <= req.target_soc_pct <= 100):
            raise ValueError("target_soc_pct out of range")

        now = int(self._clock())
        plan = compute_plan(req, self._tariffs, now_epoch_s=now,
                            plan_id=str(uuid.uuid4()))
        plan_dict = plan.to_dict()

        # Integrity-protect the cloud-to-vehicle command (CS-SEC-005).
        plan_dict["signature"] = self._auth.sign_command(plan.to_dict())
        plan_dict["issued_by"] = identity

        self._plans[req.vehicle_id] = plan_dict
        self._status[req.vehicle_id] = {
            "vehicle_id": req.vehicle_id,
            "state": "SCHEDULED",
            "reason": "plan accepted" if not plan.fallback else "plan accepted (fallback)",
            "current_soc_pct": req.current_soc_pct,
        }
        return plan_dict

    # --- Vehicle pulls its current plan ---------------------------------------
    def get_plan(self, authorization: str, vehicle_id: str) -> dict:
        self._auth.authenticate(authorization)
        plan = self._plans.get(vehicle_id)
        if plan is None:
            raise KeyError(vehicle_id)
        return plan

    # --- Status feedback (US-15 / CS-FR-031) ----------------------------------
    def report_status(self, authorization: str, body: dict) -> dict:
        self._auth.authenticate(authorization)
        vehicle_id = str(body["vehicle_id"])
        self._status[vehicle_id] = {
            "vehicle_id": vehicle_id,
            "state": str(body.get("state", "UNKNOWN")),
            "reason": str(body.get("reason", "")),
            "current_soc_pct": int(body.get("current_soc_pct", 0)),
        }
        return self._status[vehicle_id]

    def get_status(self, authorization: str, vehicle_id: str) -> dict:
        self._auth.authenticate(authorization)
        status = self._status.get(vehicle_id)
        if status is None:
            raise KeyError(vehicle_id)
        return status
