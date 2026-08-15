#!/usr/bin/env bash
# Run every unit's tests in one pass (the runnable subset of the book's
# build-and-test gate, Chapter 7.5). Requires: python3, cmake, a C++17 compiler.
set -uo pipefail
cd "$(dirname "$0")"

fail=0
section() { printf '\n========== %s ==========\n' "$1"; }

run_py() {  # $1 = unit dir
  section "Python unit: $1"
  ( cd "$1" && python3 -m unittest discover -s tests -p 'test_*.py' ) || fail=1
}

run_cpp() {  # $1 = unit dir
  section "C++ unit: $1"
  (
    cd "$1" \
      && cmake -S . -B build -DCMAKE_BUILD_TYPE=Release >/dev/null \
      && cmake --build build >/dev/null \
      && ctest --test-dir build --output-on-failure
  ) || fail=1
}

run_py  cloud/tariff-planner
run_py  cloud/schedule-api
run_py  ota
run_py  telemetry
run_cpp in-vehicle/charge-management-service
run_cpp in-vehicle/bms-interface-adapter

section "RESULT"
if [ "$fail" -eq 0 ]; then
  echo "ALL UNIT TEST SUITES PASSED"
else
  echo "ONE OR MORE SUITES FAILED"
fi
exit "$fail"
