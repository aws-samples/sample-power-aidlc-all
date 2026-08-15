# NFR Design — charge-management-service

> AI-DLC Construction artifact (Chapter 9.2). Each constraint becomes a concrete
> pattern or logical component. This is where the safety boundary becomes
> architecture.

- bms-adapter        isolates the safety boundary; only path to the BMS
- safety-monitor     watches inhibit signal; forces safe idle on loss
- plan-cache         last-known-good schedule for offline execution
- command-verifier   validates mTLS identity + message integrity

Patterns: bulkhead (isolate adapter) · fail-safe default (safe idle) · timeout/retry

## NFR -> design response mapping
| NFR | Design response |
|---|---|
| Safety (ASIL, freedom from interference) | Isolated `bms-adapter` + `safety-monitor`; AI excluded from control path |
| Real-time / timing (WCET, departure deadline) | Soft-RT scheduling with a hard, non-overridable inhibit path |
| Reliability (offline operation, degraded modes) | `plan-cache` with safe local fallback and bounded retries |
| Security (R155, command integrity) | `command-verifier` (mTLS + IAM-scoped); signed OTA packages |

## Component placement
| Logical component | Unit | Generated? |
|---|---|---|
| bms-adapter | U4 | No — human-engineered, review-gated |
| safety-monitor | U4 | No — human-engineered |
| plan-cache | U3 | Yes — QM |
| command-verifier | U3/U1 | Yes — QM (security-reviewed) |
| schedule executor, SoC tracker | U3 | Yes — QM |

The bms-adapter and safety-monitor exist specifically to contain safety-critical
behavior so the rest of the service is built and verified at QM pace.
