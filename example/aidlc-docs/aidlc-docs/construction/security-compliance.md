# Stage Completion — Security Compliance

> AI-DLC Construction artifact (Chapter 13.1). The opt-in Security Baseline
> extension turns fifteen SECURITY rules into *blocking* gate conditions. A
> non-compliant rule withholds "Continue to Next Stage" until fixed, and the
> finding is logged by rule ID in the audit trail.

## Excerpt (as it appeared at the code-generation gate)
```text
# Stage Completion — Security Compliance (excerpt)
SECURITY-01 Encryption at rest/in transit ............ compliant
SECURITY-05 Input validation on API params ........... compliant
SECURITY-06 Least-privilege IAM policies ............. NON-COMPLIANT  (blocking)
SECURITY-10 Supply chain / SBOM ...................... compliant

# audit.md
2026-06-22T14:08Z  SECURITY-06 finding: wildcard action in schedule-api role
                   -> "Continue to Next Stage" withheld until resolved
```

## Resolution
SECURITY-06 was resolved on 2026-06-23 by replacing the wildcard action in the
schedule-api IAM role with least-privilege, scoped permissions (CS-SEC-005). The
gate then re-opened. Final status:

```text
SECURITY-01 Encryption at rest/in transit ............ compliant
SECURITY-05 Input validation on API params ........... compliant
SECURITY-06 Least-privilege IAM policies ............. compliant   (resolved)
SECURITY-10 Supply chain / SBOM ...................... compliant
```

## Mapping to this repo
- SECURITY-05 — `cloud/schedule-api/schedule_api/service.py` validates request
  fields and rejects out-of-range `target_soc_pct`.
- SECURITY-06 — least-privilege credentials (modeled by scoped bearer tokens in
  `auth.py`; mTLS + IAM-scoped roles in production, infrastructure-design.md).
- SECURITY-10 — pinned dependencies + SBOM for production deployments (Chapter 13.2).
- Authentication + integrity — `auth.py` (bearer token + HMAC command signature)
  satisfies CS-SEC-005 / SECURITY authentication + integrity rules.
