// SPDX-License-Identifier: Apache-2.0
#include "charge_management/telemetry_publisher.h"

namespace charge_management {

void TelemetryPublisher::Publish(const StatusEvent& event) {
  last_ = event;
  ++count_;
  if (sink_) {
    sink_(event);
  }
}

}  // namespace charge_management
