# Audit Trail — EV Charge Scheduling Bolt

This is the human-accountable evidence spine for the feature. Every phase
appends here; nothing is overwritten. The trail is what Chapter 10 generates
operational docs from and what Chapter 12 draws on to satisfy ISO 26262,
ISO 21434, and UNECE R156.

Timestamp format: ISO 8601 (UTC).

---

## Inception — Intent Captured
**Timestamp**: 2026-06-08T10:02:00Z
**Actor**: Product Owner (mob)
**Action**: Seed intent recorded — "Let EV drivers schedule charging to a target
state of charge by a chosen departure time, minimizing energy cost and battery
wear, with the cabin pre-conditioned for departure."
**Context**: Intent bootstrap (Chapter 5.1). Safety boundary flagged at the BMS
interface; UNECE R156 applies; location/usage data flagged privacy-sensitive.

---

## Inception — Mob Elaboration
**Timestamp**: 2026-06-10T13:30:00Z
**Actor**: Cross-functional mob (PO, vehicle SW, cloud, systems/battery, safety,
security, test, supplier)
**Action**: Open questions resolved into requirements and explicit constraints.
The workflow presented a multiple-choice questionnaire
(`inception/requirements/requirements-questions.md`); the mob added a
functional-safety question (Q4) and removed an out-of-scope mobile-OS question
before answering. Decisions:
- No connectivity at departure -> execute cached schedule locally; never depend on cloud.
- Conflicting schedules -> documented precedence; safety/charge limits always win.
- Target SoC bounds -> default capped for longevity; BMS enforces hard limit independently.
- Thermal-event charge stop -> owned by BMS autonomously (constraint, not feature).
**Context**: Mob Elaboration (Chapter 5.2).

---

## Inception — Requirements Approved
**Timestamp**: 2026-06-12T09:14:00Z
**Actor**: Mob (named sign-offs: Functional Safety Eng, Systems Eng, PO, Test Eng)
**Action**: Requirements approved — CS-FR/NFR/SR/SEC set v1.
**Context**: Requirements gate (Chapter 5.3 / 5.4). requirements.md baselined.

---

## Inception — Stories, Functional Design, Units Approved
**Timestamp**: 2026-06-13T16:20:00Z
**Actor**: Mob
**Action**: User stories with acceptance criteria, technology-agnostic functional
design, and unit decomposition (U1-U6) approved. BMS interface adapter isolated
as its own safety-relevant unit (U4); U3 -> U4 sequencing set.
**Context**: Inception approval gate (Chapter 6.6).

---

## Construction — Design + NFR Design Approved
**Timestamp**: 2026-06-18T15:02:00Z
**Actor**: Mob (Mob Construction)
**Action**: Application + infrastructure design and NFR design approved. BMS
adapter isolated; mTLS + IAM-scoped credentials for cloud-to-vehicle commands;
planning in cloud with on-vehicle resolved-plan cache and safe fallback.
**Context**: Design gate (Chapters 7 and 9). ADRs recorded.

---

## Construction — Code Generation
**Timestamp**: 2026-06-22T11:10:00Z
**Actor**: AI-DLC code-generation workflow + engineers
**Action**: Per-layer generation against approved plans. Cloud units generated
end-to-end; charge-management-service skeleton + QM logic generated; bms_client
boundary logic human-engineered and review-gated.
**Context**: Code generation (Chapter 8).

---

## Construction — Security Compliance Finding (Security Baseline extension)
**Timestamp**: 2026-06-22T14:08:00Z
**Actor**: Security Baseline extension + Security Eng
**Action**: SECURITY-06 finding: wildcard action in schedule-api role
-> "Continue to Next Stage" withheld until resolved. Resolved 2026-06-23T09:40Z
by scoping the IAM role to least privilege (CS-SEC-005); gate then re-opened.
**Context**: Security gate condition (Chapter 13.1). See
construction/security-compliance.md.

---

## Construction — Build & Test PASS
**Timestamp**: 2026-06-24T11:47:00Z
**Actor**: AI-DLC build-and-test step + Test Eng
**Action**: Build & Test PASS — 142 unit / 18 integration / 6 contract; security
mTLS+auth verified; BMS boundary HIL check (inhibit honored, safe-idle on link
loss) human-reviewed.
**Context**: Build-and-test gate (Chapter 8.5).

---

## Operations — Release Signed Off
**Timestamp**: 2026-06-27T08:30:00Z
**Actor**: Quality Steward [human]
**Action**: Release v1.3.0 signed off; staged OTA rollout authorized (canary 1%
-> phased 25% -> fleet 100%) with proven rollback to v1.2.4.
**Context**: Release gate (Chapter 10.1). R156 baseline recorded per VIN.

---

## Operations — Monitoring / Loop Closed
**Timestamp**: 2026-07-27T09:00:00Z
**Actor**: Operations + AI anomaly detection; humans judge severity
**Action**: 30-day monitoring summary recorded. Readiness accuracy 97.4%; median
18% cost savings; cold-ambient early-inhibit anomaly (0.3% sessions) flagged as
candidate next-Bolt intent. No safety regressions.
**Context**: Monitoring and loop-back (Chapter 10.2-10.4).
