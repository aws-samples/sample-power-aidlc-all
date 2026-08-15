"""U1 - Schedule API & app integration (cloud).

Driver-facing, authenticated REST API that accepts a departure time / target SoC,
calls the tariff planner (U2), stores the resolved plan, and exposes status.
Traces to US-03, US-15, CS-SEC-005, CS-FR-030. QM-rated; security-sensitive.

The schedule API is internet-facing: authentication is a DESIGN requirement
(CS-SEC-005), not later hardening. Every request is authenticated (see auth.py).
"""

from .service import ScheduleService
from .auth import AuthError, TokenAuthenticator

__all__ = ["ScheduleService", "AuthError", "TokenAuthenticator"]
