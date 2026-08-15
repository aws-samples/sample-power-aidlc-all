// SPDX-License-Identifier: Apache-2.0
//
// Minimal, dependency-free test harness so the example builds anywhere with just
// a C++17 compiler and CMake/CTest. A real AUTOSAR project would use GoogleTest
// or the supplier's framework; the AI-DLC test-generation step (Chapter 7.4)
// emits tests in whatever framework the unit's tech stack specifies.

#ifndef CHARGE_MANAGEMENT_TEST_SUPPORT_H
#define CHARGE_MANAGEMENT_TEST_SUPPORT_H

#include <cstdio>
#include <string>

#include "charge_management/i_bms_adapter.h"

namespace test_support {

inline int& failures() {
  static int f = 0;
  return f;
}

inline void check(bool cond, const std::string& what) {
  if (cond) {
    std::printf("  [PASS] %s\n", what.c_str());
  } else {
    std::printf("  [FAIL] %s\n", what.c_str());
    ++failures();
  }
}

}  // namespace test_support

// A controllable fake BMS adapter standing in for the real U4 adapter / BMS.
// Lets tests drive inhibit, interface validity, and the permitted envelope.
class FakeBmsAdapter : public charge_management::IBmsAdapter {
 public:
  charge_management::BmsEnvelope envelope;     // what the BMS currently allows
  bool grant = true;                           // whether RequestCharge succeeds
  int request_calls = 0;
  int stop_calls = 0;
  double last_requested_current = -1.0;

  FakeBmsAdapter() {
    envelope.max_charge_current_a = 32.0;
    envelope.inhibit = false;
    envelope.valid = true;
  }

  charge_management::BmsEnvelope ReadEnvelope() override { return envelope; }

  bool RequestCharge(double current_a) override {
    ++request_calls;
    last_requested_current = current_a;
    if (!envelope.valid || envelope.inhibit) return false;
    return grant;
  }

  void StopCharge() override { ++stop_calls; }
};

#define RUN_TEST(fn)                       \
  do {                                     \
    std::printf("RUN %s\n", #fn);          \
    fn();                                  \
  } while (0)

#endif  // CHARGE_MANAGEMENT_TEST_SUPPORT_H
