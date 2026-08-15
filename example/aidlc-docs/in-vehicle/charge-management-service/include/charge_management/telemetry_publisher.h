// SPDX-License-Identifier: Apache-2.0
//
// Status/telemetry publisher (Unit U3 -> U6, QM, AI-generated).
// Publishes StatusEvents back toward the driver (CS-FR-031) and the fleet data
// pipeline. Privacy-sensitive fields are minimized (Chapter 6.3 / 12).

#ifndef CHARGE_MANAGEMENT_TELEMETRY_PUBLISHER_H
#define CHARGE_MANAGEMENT_TELEMETRY_PUBLISHER_H

#include <functional>
#include <vector>

#include "charge_management/domain_types.h"

namespace charge_management {

class TelemetryPublisher {
 public:
  using Sink = std::function<void(const StatusEvent&)>;

  TelemetryPublisher() = default;
  explicit TelemetryPublisher(Sink sink) : sink_(std::move(sink)) {}

  void Publish(const StatusEvent& event);

  // Number of events published in this process (useful for tests/metrics).
  std::size_t published_count() const { return count_; }

  // Last event published; empty session_id if none yet.
  const StatusEvent& last() const { return last_; }

 private:
  Sink sink_;
  StatusEvent last_;
  std::size_t count_ = 0;
};

}  // namespace charge_management

#endif  // CHARGE_MANAGEMENT_TELEMETRY_PUBLISHER_H
