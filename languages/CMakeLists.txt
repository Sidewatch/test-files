# A library and its test executable, C++20, with an optional sanitizer build.
cmake_minimum_required(VERSION 3.25)
project(Inventory VERSION 1.4.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
option(INVENTORY_ASAN "Build with AddressSanitizer" OFF)

add_library(inventory STATIC src/stock.cpp src/reorder.cpp)
target_include_directories(inventory PUBLIC include)
target_compile_definitions(inventory PRIVATE INVENTORY_VERSION="${PROJECT_VERSION}")

if(INVENTORY_ASAN)
  target_compile_options(inventory PUBLIC -fsanitize=address -fno-omit-frame-pointer)
  target_link_options(inventory PUBLIC -fsanitize=address)
endif()

find_package(Threads REQUIRED)
target_link_libraries(inventory PUBLIC Threads::Threads)

enable_testing()
add_executable(inventory_tests tests/stock_test.cpp)
target_link_libraries(inventory_tests PRIVATE inventory)
add_test(NAME stock COMMAND inventory_tests --reporter compact)

message(STATUS "Configured ${PROJECT_NAME} ${PROJECT_VERSION} (ASAN=${INVENTORY_ASAN})")
