"""Authentication for the schedule API (CS-SEC-005).

Security Baseline extension is enabled (aidlc-state.md): the schedule API is a
network-exposed endpoint, so every request MUST be authenticated and commands
MUST be integrity-protected.

This module models bearer-token auth and HMAC message-integrity in the standard
library so the example is runnable. In production this is replaced by mTLS +
IAM-scoped credentials (Chapter 6.3); the integrity check stands in for the
signed cloud-to-vehicle command.
"""

from __future__ import annotations

import hashlib
import hmac
import json
from typing import Dict


class AuthError(Exception):
    """Raised when a request fails authentication or integrity checks."""


class TokenAuthenticator:
    def __init__(self, tokens: Dict[str, str], signing_key: bytes):
        # tokens maps bearer token -> caller identity (scope/principal).
        self._tokens = dict(tokens)
        self._signing_key = signing_key

    def authenticate(self, authorization_header: str) -> str:
        """Return the caller identity for a valid 'Bearer <token>' header."""
        if not authorization_header:
            raise AuthError("missing Authorization header")
        parts = authorization_header.split(" ", 1)
        if len(parts) != 2 or parts[0].lower() != "bearer":
            raise AuthError("malformed Authorization header")
        token = parts[1].strip()
        identity = self._tokens.get(token)
        if identity is None:
            raise AuthError("invalid token")
        return identity

    def sign_command(self, payload: dict) -> str:
        """Produce an integrity signature for a cloud-to-vehicle command."""
        body = json.dumps(payload, sort_keys=True, separators=(",", ":")).encode()
        return hmac.new(self._signing_key, body, hashlib.sha256).hexdigest()

    def verify_command(self, payload: dict, signature: str) -> None:
        """Verify a command's integrity signature; raise on mismatch."""
        expected = self.sign_command(payload)
        if not hmac.compare_digest(expected, signature or ""):
            raise AuthError("command integrity check failed")
