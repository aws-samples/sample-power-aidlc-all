# Domain Entities — charge-management-service

> AI-DLC Construction artifact. The vocabulary the service reasons about,
> technology-agnostic.

## ChargePlan
- `plan_id`            stable identifier (traceable to cloud-issued plan)
- `target_soc_pct`     desired state of charge at departure (e.g., 80)
- `departure_time`     absolute time the vehicle must be ready
- `precondition_window` minutes before departure to start cabin pre-conditioning
- `charge_windows[]`    ordered cheap/off-peak windows (start, end)
- `issued_at`          when the plan was computed (used for staleness/conflict)
- `source`             APP | RECURRING | DEMAND_RESPONSE  (precedence; BR-04)

## BmsEnvelope (read-only, owned by BMS via adapter U4)
- `max_charge_current_a`  maximum permitted charge current
- `inhibit`               authoritative stop signal (true => no charging; BR-02)
- `valid`                 false when the BMS interface is lost (BR-03)

## ChargeSession
- `state`              IDLE | REQUESTING | CHARGING | COMPLETE | SAFE_IDLE | FAULT
- `current_soc_pct`    latest measured state of charge
- `started_at`         when charging began
- `reason`             plain-language status reason for the driver (CS-FR-031)

## StatusEvent (-> telemetry U6 / app U1)
- `session_id`, `state`, `current_soc_pct`, `reason`, `timestamp`

## Invariants
- A `ChargeSession` may be `CHARGING` only while `BmsEnvelope.inhibit == false`
  and `BmsEnvelope.valid == true`.
- Cost optimization may reorder `charge_windows` but may never violate the
  envelope or the departure deadline (BR-04).
