"""OTA packaging and signing (U5).

An OTA package binds an artifact to its version and, crucially, to the
requirement baseline it satisfies (UNECE R156): every delivered version is
traceable to the CS-FR/NFR/SR set it implements. Packages are signed so the
vehicle can verify integrity and provenance before install (Chapter 6.3 / 12).
"""

from __future__ import annotations

import hashlib
import hmac
import json
from dataclasses import dataclass, field
from typing import List


@dataclass
class OtaPackage:
    component: str
    version: str
    artifact_sha256: str
    requirement_baseline: List[str]  # R156: requirements this version satisfies
    previous_version: str = ""        # for rollback
    signature: str = ""

    def manifest(self) -> dict:
        return {
            "component": self.component,
            "version": self.version,
            "artifact_sha256": self.artifact_sha256,
            "requirement_baseline": sorted(self.requirement_baseline),
            "previous_version": self.previous_version,
        }


def _sign(manifest: dict, signing_key: bytes) -> str:
    body = json.dumps(manifest, sort_keys=True, separators=(",", ":")).encode()
    return hmac.new(signing_key, body, hashlib.sha256).hexdigest()


def build_package(component: str, version: str, artifact_bytes: bytes,
                  requirement_baseline: List[str], signing_key: bytes,
                  previous_version: str = "") -> OtaPackage:
    sha = hashlib.sha256(artifact_bytes).hexdigest()
    pkg = OtaPackage(
        component=component,
        version=version,
        artifact_sha256=sha,
        requirement_baseline=list(requirement_baseline),
        previous_version=previous_version,
    )
    pkg.signature = _sign(pkg.manifest(), signing_key)
    return pkg


def verify_package(pkg: OtaPackage, artifact_bytes: bytes,
                   signing_key: bytes) -> bool:
    """Verify the package signature and that the artifact matches the digest."""
    if hashlib.sha256(artifact_bytes).hexdigest() != pkg.artifact_sha256:
        return False
    expected = _sign(pkg.manifest(), signing_key)
    return hmac.compare_digest(expected, pkg.signature or "")
