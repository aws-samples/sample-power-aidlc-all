// SPDX-License-Identifier: Apache-2.0
//
// SoC tracking and charge-time estimation (Unit U3, QM, AI-generated).
// Used by the schedule executor to decide the latest moment charging must start
// to reach the target SoC by departure (CS-FR-014).

#ifndef CHARGE_MANAGEMENT_SOC_TRACKER_H
#define CHARGE_MANAGEMENT_SOC_TRACKER_H

namespace charge_management {

class SocTracker {
 public:
  // battery_capacity_kwh: usable pack energy; pack_voltage_v: nominal voltage.
  SocTracker(int initial_soc_pct, double battery_capacity_kwh,
             double pack_voltage_v);

  int current_soc() const { return current_soc_pct_; }

  // Update with a freshly measured SoC (clamped to [0, 100]).
  void Update(int measured_soc_pct);

  bool ReachedTarget(int target_soc_pct) const {
    return current_soc_pct_ >= target_soc_pct;
  }

  // Estimate minutes to charge from current SoC to target at `charge_current_a`.
  // Returns 0 if already at/above target; returns a large sentinel if current
  // is non-positive (cannot make progress).
  int EstimateMinutesToTarget(int target_soc_pct, double charge_current_a) const;

 private:
  int current_soc_pct_;
  double battery_capacity_kwh_;
  double pack_voltage_v_;
};

}  // namespace charge_management

#endif  // CHARGE_MANAGEMENT_SOC_TRACKER_H
