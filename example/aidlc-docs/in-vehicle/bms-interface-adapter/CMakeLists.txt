# SPDX-License-Identifier: Apache-2.0
# Unit U4 — bms-interface-adapter (SAFETY-RELEVANT, human-engineered).
cmake_minimum_required(VERSION 3.16)
project(bms_interface_adapter LANGUAGES CXX VERSION 1.3.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()
add_compile_options(-Wall -Wextra)

add_library(bms_interface_adapter
  src/safety_monitor.cpp
  src/bms_interface_adapter.cpp
)
target_include_directories(bms_interface_adapter PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

enable_testing()
add_executable(test_bms_adapter tests/test_bms_adapter.cpp)
target_link_libraries(test_bms_adapter PRIVATE bms_interface_adapter)
add_test(NAME bms_adapter COMMAND test_bms_adapter)
