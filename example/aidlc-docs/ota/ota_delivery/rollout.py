"""Staged OTA rollout controller (U5).

Models the human-gated, staged rollout of Chapter 9.1: canary (1%) -> phased
(25%) -> fleet (100%), advancing only while KPIs hold and rolling back on a
breach. Rollback is first-class: the previous version is retained on-vehicle.

The release GATE itself is a human decision (Quality Steward sign-off); this
controller assembles and executes the strategy a person approves.
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from typing import List, Optional

from .packager import OtaPackage


class RolloutStage(Enum):
    CANARY = 1      # ~1% of the fleet
    PHASED = 25     # ~25%
    FLEET = 100     # 100%
    ROLLED_BACK = -1


# Ordered progression of healthy stages.
_PROGRESSION = [RolloutStage.CANARY, RolloutStage.PHASED, RolloutStage.FLEET]


@dataclass
class KpiSample:
    readiness_accuracy_pct: float   # goal >= 95 (Chapter 9.2)
    safe_idle_regressions: int      # must be 0 (safety signal)


class RolloutController:
    def __init__(self, package: OtaPackage, fleet_size: int,
                 min_readiness_pct: float = 95.0):
        if not package.previous_version:
            # Rollback must be possible before any rollout begins.
            raise ValueError("package has no previous_version; rollback not possible")
        self.package = package
        self.fleet_size = fleet_size
        self.min_readiness_pct = min_readiness_pct
        self.stage: Optional[RolloutStage] = None
        self.history: List[RolloutStage] = []
        self.signed_off = False

    def sign_off(self, quality_steward: str) -> None:
        """Human release gate. Rollout cannot start until this is called."""
        if not quality_steward:
            raise ValueError("a named Quality Steward is required to sign off")
        self.signed_off = True

    def vehicles_in_stage(self, stage: RolloutStage) -> int:
        if stage.value <= 0:
            return 0
        return max(1, (self.fleet_size * stage.value) // 100)

    def start(self) -> RolloutStage:
        if not self.signed_off:
            raise RuntimeError("release not signed off (human gate, Chapter 9.1)")
        self.stage = RolloutStage.CANARY
        self.history.append(self.stage)
        return self.stage

    def _healthy(self, kpi: KpiSample) -> bool:
        return (kpi.readiness_accuracy_pct >= self.min_readiness_pct
                and kpi.safe_idle_regressions == 0)

    def advance(self, kpi: KpiSample) -> RolloutStage:
        """Advance to the next stage if KPIs hold; otherwise roll back."""
        if self.stage is None:
            raise RuntimeError("rollout not started")
        if self.stage in (RolloutStage.FLEET, RolloutStage.ROLLED_BACK):
            return self.stage

        if not self._healthy(kpi):
            return self.rollback()

        idx = _PROGRESSION.index(self.stage)
        self.stage = _PROGRESSION[idx + 1]
        self.history.append(self.stage)
        return self.stage

    def rollback(self) -> RolloutStage:
        """Revert affected vehicles to the retained previous version."""
        self.stage = RolloutStage.ROLLED_BACK
        self.history.append(self.stage)
        return self.stage

    @property
    def active_version(self) -> str:
        if self.stage == RolloutStage.ROLLED_BACK:
            return self.package.previous_version
        return self.package.version
