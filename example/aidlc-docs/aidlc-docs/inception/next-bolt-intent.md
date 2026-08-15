# Captured Intent — next Bolt

> AI-DLC Operations -> Inception loop-back (Chapter 10.4). A field signal becomes
> new intent and runs the same Inception -> Construction -> Operations path, with
> the same gates and the same safety boundary.

```text
Intent:   Improve cold-ambient pre-conditioning so target SoC and cabin
          readiness hold below 0 C, without changing the BMS safety path.
Source:   Operations monitoring v1.3.0 (early-inhibit anomaly, 0.3% sessions)
In scope: scheduler/pre-conditioning logic (QM)
Out of scope: BMS thermal control (safety-relevant; unchanged)
```

The new work inherits the existing safety boundary: U4 (bms-interface-adapter)
is unchanged, generative AI stays off the control path, and the vehicle improves
over its lifetime without ever putting AI on the inhibit logic.
