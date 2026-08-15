// SPDX-License-Identifier: Apache-2.0
#include "charge_management/soc_tracker.h"

#include <algorithm>

namespace charge_management {

namespace {
constexpr int kUnreachableMinutes = 1'000'000;  // sentinel: cannot make progress
}

SocTracker::SocTracker(int initial_soc_pct, double battery_capacity_kwh,
                       double pack_voltage_v)
    : current_soc_pct_(std::clamp(initial_soc_pct, 0, 100)),
      battery_capacity_kwh_(battery_capacity_kwh),
      pack_voltage_v_(pack_voltage_v) {}

void SocTracker::Update(int measured_soc_pct) {
  current_soc_pct_ = std::clamp(measured_soc_pct, 0, 100);
}

int SocTracker::EstimateMinutesToTarget(int target_soc_pct,
                                        double charge_current_a) const {
  const int target = std::clamp(target_soc_pct, 0, 100);
  if (current_soc_pct_ >= target) {
    return 0;
  }
  if (charge_current_a <= 0.0 || pack_voltage_v_ <= 0.0 ||
      battery_capacity_kwh_ <= 0.0) {
    return kUnreachableMinutes;
  }

  // Energy needed (kWh) to move from current SoC to target.
  const double soc_delta = (target - current_soc_pct_) / 100.0;
  const double energy_needed_kwh = soc_delta * battery_capacity_kwh_;

  // Charge power (kW) = V * I / 1000. Minutes = energy / power * 60.
  const double power_kw = (pack_voltage_v_ * charge_current_a) / 1000.0;
  const double hours = energy_needed_kwh / power_kw;
  const int minutes = static_cast<int>(hours * 60.0 + 0.5);
  return std::max(minutes, 1);
}

}  // namespace charge_management
