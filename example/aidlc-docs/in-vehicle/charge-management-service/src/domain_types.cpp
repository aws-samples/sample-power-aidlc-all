// SPDX-License-Identifier: Apache-2.0
#include "charge_management/domain_types.h"

namespace charge_management {

const char* to_string(ChargeState s) {
  switch (s) {
    case ChargeState::Idle: return "IDLE";
    case ChargeState::Requesting: return "REQUESTING";
    case ChargeState::Charging: return "CHARGING";
    case ChargeState::Complete: return "COMPLETE";
    case ChargeState::SafeIdle: return "SAFE_IDLE";
    case ChargeState::Fault: return "FAULT";
  }
  return "UNKNOWN";
}

const char* to_string(PlanSource s) {
  switch (s) {
    case PlanSource::App: return "APP";
    case PlanSource::Recurring: return "RECURRING";
    case PlanSource::DemandResponse: return "DEMAND_RESPONSE";
  }
  return "UNKNOWN";
}

}  // namespace charge_management
