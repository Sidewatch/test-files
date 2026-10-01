# Warehouse inventory library and tools, C++20, with optional sanitizers.
# Comments start with a hash and run to the end of the line.
#[[ A bracket comment
    spanning several lines. TODO: add install rules for the docs. ]]
#[==[ A bracket comment with level-2 brackets ]==]

cmake_minimum_required(VERSION 3.25 FATAL_ERROR)
cmake_policy(SET CMP0135 NEW)

project(Inventory
  VERSION 1.4.0
  DESCRIPTION "Warehouse stock tracking"
  HOMEPAGE_URL "https://example.com/inventory"
  LANGUAGES CXX)

# ── Variables and properties ────────────────────────────────────────
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
set(INVENTORY_SOURCES src/stock.cpp src/reorder.cpp)
set(CACHED_VALUE "default" CACHE STRING "A cached string" FORCE)
set(ENV{INVENTORY_HOME} "$ENV{HOME}/inventory")
set(MULTI_LINE_LIST
  alpha
  beta   # inline comment between arguments
  gamma)
set(QUOTED "A \"quoted\" string with \\ backslash, \n newline, \t tab and ${PROJECT_NAME} reference")
set(BRACKET_ARG [=[bracket argument: no ${expansion}, no \escapes]=])
set(NESTED_REF "${${PROJECT_NAME}_SUFFIX}")
set(GENEX_USE "$<$<CONFIG:Debug>:-DDEBUG>")
unset(CACHED_VALUE CACHE)
mark_as_advanced(CACHED_VALUE)

# ── Options and feature checks ──────────────────────────────────────
option(INVENTORY_ASAN "Build with AddressSanitizer" OFF)
option(INVENTORY_BUILD_TESTS "Build the test suite" ON)
option(BUILD_SHARED_LIBS "Build shared libraries" OFF)

include(CheckCXXCompilerFlag)
include(GNUInstallDirs)
include(CTest)
include(FetchContent)
check_cxx_compiler_flag("-Wall" HAS_WALL)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

# ── Targets ─────────────────────────────────────────────────────────
add_library(inventory STATIC ${INVENTORY_SOURCES})
add_library(Inventory::inventory ALIAS inventory)
add_library(inventory_iface INTERFACE)
add_library(inventory_objs OBJECT src/stock.cpp)
add_library(inventory_imported SHARED IMPORTED)
add_executable(inventory_cli src/main.cpp)
add_custom_target(docs COMMAND doxygen Doxyfile WORKING_DIRECTORY ${CMAKE_SOURCE_DIR} COMMENT "Generating docs")

target_include_directories(inventory
  PUBLIC  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
          $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
  PRIVATE src)
target_compile_definitions(inventory PRIVATE INVENTORY_VERSION="${PROJECT_VERSION}" $<$<CONFIG:Debug>:INVENTORY_DEBUG>)
target_compile_features(inventory PUBLIC cxx_std_20)
target_link_libraries(inventory_cli PRIVATE inventory)
set_target_properties(inventory PROPERTIES
  VERSION ${PROJECT_VERSION}
  SOVERSION ${PROJECT_VERSION_MAJOR}
  POSITION_INDEPENDENT_CODE ON)

if(MSVC)
  target_compile_options(inventory PRIVATE /W4 /permissive-)
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  target_compile_options(inventory PRIVATE -Wall -Wextra -Wpedantic)
else()
  message(WARNING "Unknown compiler ${CMAKE_CXX_COMPILER_ID}")
endif()

if(INVENTORY_ASAN)
  target_compile_options(inventory PUBLIC -fsanitize=address -fno-omit-frame-pointer)
  target_link_options(inventory PUBLIC -fsanitize=address)
endif()

if(APPLE AND NOT IOS)
  set(PLATFORM_LIBS "-framework Foundation")
elseif(UNIX)
  set(PLATFORM_LIBS pthread dl)
elseif(WIN32)
  set(PLATFORM_LIBS ws2_32)
endif()

# ── Conditions of every kind ────────────────────────────────────────
if(DEFINED ENV{CI} AND "$ENV{CI}" STREQUAL "true")
  message(STATUS "Running in CI")
endif()
if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.20 AND NOT CMAKE_VERSION VERSION_LESS 3.25)
  message(STATUS "Modern CMake")
endif()
if(EXISTS "${CMAKE_SOURCE_DIR}/extra.cmake" AND IS_DIRECTORY "${CMAKE_SOURCE_DIR}/src")
  include("${CMAKE_SOURCE_DIR}/extra.cmake" OPTIONAL)
endif()
if(TARGET inventory AND COMMAND target_sources AND POLICY CMP0135)
  message(STATUS "Target present")
endif()
if(PROJECT_VERSION MATCHES "^([0-9]+)\\.([0-9]+)")
  message(STATUS "Major ${CMAKE_MATCH_1} minor ${CMAKE_MATCH_2}")
endif()
if(NUM LESS 3 OR NUM GREATER 10 OR NUM EQUAL 5 OR (NOT DEFINED NUM))
  set(NUM_OK TRUE)
endif()
if(A STRLESS B AND C STRGREATER D AND E STREQUAL F AND G IN_LIST H)
  set(ORDER_OK YES)
endif()

# ── Loops and functions ─────────────────────────────────────────────
foreach(src IN LISTS INVENTORY_SOURCES)
  message(STATUS "source: ${src}")
endforeach()
foreach(i RANGE 0 4 2)
  math(EXPR doubled "${i} * 2")
endforeach()
foreach(key value IN ZIP_LISTS KEYS VALUES)
  message(STATUS "${key}=${value}")
endforeach()
while(counter LESS 3)
  math(EXPR counter "${counter} + 1")
  if(counter EQUAL 2)
    continue()
  endif()
  break()
endwhile()

function(add_inventory_test name)
  cmake_parse_arguments(ARG "QUICK" "TIMEOUT" "SOURCES;LIBS" ${ARGN})
  add_executable(${name} ${ARG_SOURCES})
  target_link_libraries(${name} PRIVATE inventory ${ARG_LIBS})
  add_test(NAME ${name} COMMAND ${name} --reporter compact)
  if(ARG_TIMEOUT)
    set_tests_properties(${name} PROPERTIES TIMEOUT ${ARG_TIMEOUT})
  endif()
  set(${name}_DONE TRUE PARENT_SCOPE)
endfunction()

macro(report_var var)
  message(STATUS "${var} = ${${var}}")
endmacro()

# ── Strings, lists, files ───────────────────────────────────────────
string(TOUPPER "${PROJECT_NAME}" UPPER_NAME)
string(REPLACE "." "_" VERSION_UNDERSCORE "${PROJECT_VERSION}")
string(REGEX REPLACE "[^A-Za-z0-9]" "_" SAFE "${PROJECT_NAME}")
string(APPEND OUT "text")
list(APPEND INVENTORY_SOURCES src/extra.cpp)
list(LENGTH INVENTORY_SOURCES SOURCE_COUNT)
list(SORT INVENTORY_SOURCES)
list(FILTER INVENTORY_SOURCES EXCLUDE REGEX "test")
file(GLOB_RECURSE HEADERS CONFIGURE_DEPENDS "include/*.hpp")
file(READ "VERSION.txt" VERSION_TEXT)
file(WRITE "${CMAKE_BINARY_DIR}/stamp.txt" "built\n")
configure_file(config.h.in "${CMAKE_BINARY_DIR}/config.h" @ONLY)
get_filename_component(ABS_PATH "../data" ABSOLUTE)
cmake_path(GET ABS_PATH FILENAME FILE_NAME)

# ── Dependencies ────────────────────────────────────────────────────
find_package(Threads REQUIRED)
find_package(fmt 10 CONFIG QUIET)
find_package(Boost 1.80 COMPONENTS filesystem system OPTIONAL_COMPONENTS regex)
find_program(DOXYGEN_EXECUTABLE doxygen)
find_library(M_LIB m)
find_path(FMT_INCLUDE fmt/core.h)
target_link_libraries(inventory PUBLIC Threads::Threads ${PLATFORM_LIBS})

FetchContent_Declare(
  catch2
  GIT_REPOSITORY https://example.com/catch2.git
  GIT_TAG        v3.5.0
  GIT_SHALLOW    TRUE)

# ── Tests, subdirectories, install ──────────────────────────────────
if(INVENTORY_BUILD_TESTS)
  enable_testing()
  add_executable(inventory_tests tests/stock_test.cpp)
  target_link_libraries(inventory_tests PRIVATE inventory)
  add_test(NAME stock COMMAND inventory_tests --reporter compact)
  add_inventory_test(reorder_test SOURCES tests/reorder_test.cpp QUICK TIMEOUT 30)
  add_subdirectory(tests/integration EXCLUDE_FROM_ALL)
endif()

install(TARGETS inventory inventory_cli
  EXPORT InventoryTargets
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(DIRECTORY include/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
install(EXPORT InventoryTargets NAMESPACE Inventory:: DESTINATION lib/cmake/Inventory)

set(CPACK_PACKAGE_NAME "inventory")
include(CPack)

message(STATUS "Configured ${PROJECT_NAME} ${PROJECT_VERSION} (ASAN=${INVENTORY_ASAN})")
message(FATAL_ERROR "unreachable" "")

# ── Further constructs ──────────────────────────────────────────────
# (placed after the final message() so the file still reads top to bottom;
#  everything below is syntactically valid but never reached at configure time)
if(FALSE)
  # Generator expressions in many positions
  target_compile_options(inventory PRIVATE
    "$<$<COMPILE_LANGUAGE:CXX>:-fno-exceptions>"
    "$<$<AND:$<CONFIG:Release>,$<CXX_COMPILER_ID:GNU,Clang>>:-O3>"
    "$<$<NOT:$<BOOL:${INVENTORY_ASAN}>>:-DNDEBUG>"
    "$<IF:$<PLATFORM_ID:Windows>,/EHsc,-pthread>"
    "$<$<VERSION_GREATER_EQUAL:$<CXX_COMPILER_VERSION>,12>:-Wno-deprecated>"
    "$<$<STREQUAL:$<TARGET_PROPERTY:TYPE>,STATIC_LIBRARY>:-fPIC>"
    "$<TARGET_FILE:inventory>" "$<TARGET_FILE_DIR:inventory>" "$<TARGET_OBJECTS:inventory_objs>"
    "$<JOIN:${INVENTORY_SOURCES},;>" "$<LOWER_CASE:UPPER>" "$<UPPER_CASE:lower>" "$<LIST:LENGTH,a;b>"
    "$<SHELL_PATH:/some/path>" "$<ANGLE-R>" "$<COMMA>" "$<SEMICOLON>" "$<0:ignored>" "$<1:kept>"
    "$<BUILD_INTERFACE:include>" "$<INSTALL_INTERFACE:include>" "$<LINK_LANGUAGE:CXX>"
    "$<TARGET_PROPERTY:inventory,INTERFACE_INCLUDE_DIRECTORIES>" "$<INSTALL_PREFIX>" "$<CONFIG>")

  # Variable references of every kind
  message("${VAR}" "$ENV{PATH}" "$CACHE{CVAR}" "${VAR_${INNER}}" "@ATONLY@" "${CMAKE_CURRENT_LIST_DIR}")
  message("${CMAKE_MATCH_0} ${CMAKE_MATCH_1} ${CMAKE_SOURCE_DIR} ${CMAKE_BINARY_DIR} ${PROJECT_SOURCE_DIR}")

  # Quoted, unquoted, and bracket arguments
  set(UNQUOTED a;b;c "quoted;list" [[bracket;list]] [=[level one ]] ]=] [==[level two ]=] ]==])
  set(ESC "\"quote\" \\backslash \$dollar \@at \; semicolon \t tab \r CR \n NL")
  set(LINE_CONT "first \
second")
  set(EMPTY "")
  message(STATUS "${EMPTY}")

  # Policies, version checks, includes
  cmake_policy(VERSION 3.25)
  cmake_policy(PUSH)
  cmake_policy(SET CMP0077 OLD)
  cmake_policy(GET CMP0077 POLICY_VALUE)
  cmake_policy(POP)
  include(${CMAKE_CURRENT_LIST_DIR}/helpers.cmake OPTIONAL RESULT_VARIABLE HELPERS_FOUND NO_POLICY_SCOPE)
  include_guard(GLOBAL)
  cmake_language(CALL message STATUS "dynamic call")
  cmake_language(EVAL CODE "message(STATUS evaluated)")
  cmake_language(DEFER DIRECTORY "${CMAKE_SOURCE_DIR}" CALL message "deferred")
  cmake_host_system_information(RESULT HOSTNAME QUERY HOSTNAME)

  # More commands
  add_compile_definitions(WITH_FOO=1 $<$<CONFIG:Debug>:DEBUG>)
  add_compile_options(-Wall)
  add_link_options(-Wl,--as-needed)
  add_definitions(-DLEGACY)
  include_directories(SYSTEM include)
  link_directories(/opt/lib)
  link_libraries(m)
  add_dependencies(docs inventory)
  add_custom_command(
    OUTPUT generated.cpp
    COMMAND ${CMAKE_COMMAND} -E echo "generating"
    COMMAND python3 gen.py --out generated.cpp
    DEPENDS gen.py
    BYPRODUCTS extra.log
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMENT "Generating sources"
    VERBATIM
    USES_TERMINAL)
  add_custom_command(TARGET inventory POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:inventory> ${CMAKE_BINARY_DIR}/out)
  source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR} PREFIX "Sources" FILES ${INVENTORY_SOURCES})
  set_source_files_properties(src/stock.cpp PROPERTIES COMPILE_FLAGS "-O2" GENERATED TRUE)
  set_property(TARGET inventory PROPERTY CXX_STANDARD 20)
  set_property(GLOBAL PROPERTY USE_FOLDERS ON)
  set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS A=1)
  set_property(CACHE BUILD_TYPE PROPERTY STRINGS Debug Release RelWithDebInfo MinSizeRel)
  get_property(STD TARGET inventory PROPERTY CXX_STANDARD)
  get_target_property(OUT_NAME inventory OUTPUT_NAME)
  get_cmake_property(ALL_VARS VARIABLES)
  get_directory_property(DEFS COMPILE_DEFINITIONS)
  define_property(GLOBAL PROPERTY MY_PROP BRIEF_DOCS "brief" FULL_DOCS "full")
  target_sources(inventory PRIVATE FILE_SET HEADERS BASE_DIRS include FILES include/a.hpp)
  target_precompile_headers(inventory PRIVATE <vector> <string> "pch.hpp")
  set_target_properties(inventory PROPERTIES UNITY_BUILD ON INTERPROCEDURAL_OPTIMIZATION ON)
  set_tests_properties(stock PROPERTIES LABELS "unit;fast" ENVIRONMENT "A=1;B=2" WILL_FAIL FALSE)
  add_test(NAME cli COMMAND inventory_cli --help CONFIGURATIONS Release WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
  ctest_start(Experimental)
  try_compile(COMPILES ${CMAKE_BINARY_DIR}/try SOURCES try.cpp CXX_STANDARD 20 OUTPUT_VARIABLE TRY_OUT)
  try_run(RUN_RESULT COMPILE_RESULT ${CMAKE_BINARY_DIR}/tryrun try.cpp RUN_OUTPUT_VARIABLE RUN_OUT)
  execute_process(COMMAND git rev-parse HEAD OUTPUT_VARIABLE GIT_SHA OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET RESULT_VARIABLE GIT_RC WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
  file(DOWNLOAD https://example.com/a.txt ${CMAKE_BINARY_DIR}/a.txt EXPECTED_HASH SHA256=0000000000000000000000000000000000000000000000000000000000000000 SHOW_PROGRESS)
  file(COPY a.txt DESTINATION ${CMAKE_BINARY_DIR} FILE_PERMISSIONS OWNER_READ OWNER_WRITE)
  file(STRINGS version.txt LINES LIMIT_COUNT 5 REGEX "^[0-9]")
  file(GENERATE OUTPUT out.txt CONTENT "$<TARGET_FILE:inventory>")
  file(RELATIVE_PATH REL ${CMAKE_SOURCE_DIR} ${CMAKE_BINARY_DIR})
  file(TO_CMAKE_PATH "C:\\x" CMAKEPATH)
  file(SHA256 a.txt HASH)
  file(LOCK ${CMAKE_BINARY_DIR}/lock GUARD FUNCTION TIMEOUT 5)
  string(JSON VALUE GET "{\"a\": [1, 2]}" a 0)
  string(TIMESTAMP NOW "%Y-%m-%d" UTC)
  string(MAKE_C_IDENTIFIER "a-b" ID)
  string(RANDOM LENGTH 8 ALPHABET abc RAND)
  string(CONFIGURE "@A@ ${B}" OUT @ONLY ESCAPE_QUOTES)
  string(LENGTH "abc" LEN)
  string(FIND "abc" "b" POS REVERSE)
  string(SUBSTRING "abcdef" 1 3 SUB)
  string(STRIP "  x  " STRIPPED)
  string(COMPARE EQUAL "a" "a" SAME)
  string(HEX "abc" HEXED)
  string(UUID ID NAMESPACE 6ba7b810-9dad-11d1-80b4-00c04fd430c8 NAME "x" TYPE SHA1)
  list(TRANSFORM LST TOUPPER REGEX "^a")
  list(JOIN LST "," JOINED)
  list(POP_BACK LST OUT)
  list(REMOVE_DUPLICATES LST)
  list(INSERT LST 0 first)
  list(FIND LST x IDX)
  list(SUBLIST LST 0 2 SUB)
  list(REVERSE LST)
  list(GET LST 0 -1 VALUES)
  math(EXPR RES "(1 + 2) * 3 << 1 | 0xF" OUTPUT_FORMAT HEXADECIMAL)
  block(SCOPE_FOR VARIABLES POLICIES)
    set(LOCAL_ONLY 1)
  endblock()
  return(PROPAGATE LOCAL_ONLY)
  separate_arguments(ARGS UNIX_COMMAND "a b 'c d'")
  variable_watch(WATCHED)
  site_name(HOST)
  load_cache(${CMAKE_BINARY_DIR} READ_WITH_PREFIX pre_ VAR)
  export(TARGETS inventory NAMESPACE Inventory:: FILE InventoryTargets.cmake)
  export(PACKAGE Inventory)
  install(FILES a.hpp DESTINATION include COMPONENT dev PERMISSIONS OWNER_READ GROUP_READ)
  install(SCRIPT post.cmake)
  install(CODE "message(STATUS \"installing\")")
  install(PROGRAMS tool.sh TYPE BIN)
  install(TARGETS inventory FILE_SET HEADERS DESTINATION include)
  install(RUNTIME_DEPENDENCY_SET deps)
  include(CMakePackageConfigHelpers)
  write_basic_package_version_file(InventoryConfigVersion.cmake VERSION ${PROJECT_VERSION} COMPATIBILITY SameMajorVersion)
  configure_package_config_file(Config.cmake.in InventoryConfig.cmake INSTALL_DESTINATION lib/cmake/Inventory)
  set(CPACK_GENERATOR "TGZ;ZIP")
  set(CPACK_SOURCE_IGNORE_FILES "/build/;/\\.git/")
  find_package(PkgConfig REQUIRED)
  pkg_check_modules(GLIB REQUIRED IMPORTED_TARGET glib-2.0)
  find_file(HEADER_FILE NAMES a.h PATHS /usr/include NO_DEFAULT_PATH)
  find_package_handle_standard_args(Foo REQUIRED_VARS FOO_LIB FOO_INC VERSION_VAR FOO_VERSION)
  FetchContent_MakeAvailable(catch2)
  FetchContent_GetProperties(catch2)
  ExternalProject_Add(ext GIT_REPOSITORY https://example.com/ext.git CMAKE_ARGS -DX=1 BUILD_BYPRODUCTS <INSTALL_DIR>/lib/libext.a)
  enable_language(C)
  include(CheckIncludeFile)
  check_include_file(unistd.h HAVE_UNISTD_H)
  check_symbol_exists(fork "unistd.h" HAVE_FORK)
  check_type_size("long" SIZEOF_LONG)
  check_c_source_compiles("int main(void){return 0;}" CAN_COMPILE)
  find_package(Python3 3.8 COMPONENTS Interpreter Development REQUIRED)
  find_package(OpenMP)
  find_package(CUDAToolkit)
  message(AUTHOR_WARNING "author" )
  message(DEPRECATION "deprecated")
  message(SEND_ERROR "error but continues")
  message(CHECK_START "Looking")
  message(CHECK_PASS "found")
  message(CHECK_FAIL "not found")
  message(NOTICE "notice")
  message(VERBOSE "verbose")
  message(DEBUG "debug")
  message(TRACE "trace")
  cmake_minimum_required(VERSION 3.25...3.30)
  cmake_path(SET P NORMALIZE "a/../b")
  cmake_path(APPEND P "c")
  cmake_path(REPLACE_EXTENSION P ".txt")
  cmake_path(IS_ABSOLUTE P ABS)
  cmake_path(GET P EXTENSION LAST_ONLY EXT)
  while(TRUE)
    break()
  endwhile()
  foreach(item IN ITEMS a b c)
    list(APPEND ITEMS_OUT ${item})
  endforeach()
  foreach(a b IN ZIP_LISTS LA LB)
  endforeach()
  function(nested_fn)
    macro(inner_macro)
      message(STATUS "${ARGC} ${ARGV} ${ARGN} ${ARGV0} ${ARGV1}")
    endmacro()
    cmake_parse_arguments(PARSE_ARGV 0 A "OPT" "ONE" "MULTI")
    set(${ARGV0}_out "x" PARENT_SCOPE)
    set(CACHE_ME "x" CACHE INTERNAL "doc")
    return()
  endfunction()
  # TODO: add a package config file and exports.
endif()
