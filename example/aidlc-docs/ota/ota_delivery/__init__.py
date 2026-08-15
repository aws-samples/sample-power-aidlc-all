"""U5 - OTA packaging & delivery (cloud + vehicle).

Packages and signs the in-vehicle charge-management component, records the R156
requirement baseline for every delivered version, and drives a staged rollout
(canary -> phased -> fleet) with first-class rollback. QM-rated; release-governed.

Traces to: OTA intent, UNECE R156 baseline.
"""

from .packager import OtaPackage, build_package, verify_package
from .rollout import RolloutController, RolloutStage

__all__ = [
    "OtaPackage",
    "build_package",
    "verify_package",
    "RolloutController",
    "RolloutStage",
]
