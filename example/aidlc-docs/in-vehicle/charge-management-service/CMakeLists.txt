# SPDX-License-Identifier: Apache-2.0
# Charge-management service (Unit U3) — AUTOSAR Adaptive-style C++ app.
# Builds with a plain C++17 toolchain so the book example is runnable without
# the AUTOSAR SDK.

cmake_minimum_required(VERSION 3.16)
project(charge_management_service LANGUAGES CXX VERSION 1.3.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

add_compile_options(-Wall -Wextra)

# Core library (QM, AI-generated) + the review-gated boundary client.
add_library(charge_management
  src/domain_types.cpp
  src/soc_tracker.cpp
  src/schedule_executor.cpp
  src/telemetry_publisher.cpp
  src/bms_client.cpp   # SAFETY-RELEVANT, review-gated (CS-SR-002/003)
)
target_include_directories(charge_management PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

# Service application binary (demo simulation).
add_executable(charge_management_service src/main.cpp)
target_link_libraries(charge_management_service PRIVATE charge_management)

# Tests
enable_testing()

add_executable(test_schedule_executor tests/test_schedule_executor.cpp)
target_include_directories(test_schedule_executor PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/tests)
target_link_libraries(test_schedule_executor PRIVATE charge_management)
add_test(NAME schedule_executor COMMAND test_schedule_executor)

add_executable(test_soc_tracker tests/test_soc_tracker.cpp)
target_include_directories(test_soc_tracker PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/tests)
target_link_libraries(test_soc_tracker PRIVATE charge_management)
add_test(NAME soc_tracker COMMAND test_soc_tracker)
