# CMake 4.1 (CMake 4.x policy baseline; local cmake is newer) — syntax showcase
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

# ── CMake 3.26 – 4.1 additions (parsed, never executed) ─────────────
if(FALSE)
  cmake_minimum_required(VERSION 3.25...4.1)
  cmake_policy(VERSION 3.31...4.1)

  # C++ modules and standard-library modules
  set(CMAKE_CXX_STANDARD 23)
  set(CMAKE_CXX_MODULE_STD ON)
  add_library(modular)
  target_sources(modular
    PUBLIC
      FILE_SET CXX_MODULES
      BASE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/modules
      FILES modules/stock.cppm modules/reorder.cppm
    PRIVATE
      FILE_SET HEADERS
      BASE_DIRS include
      FILES include/stock.hpp)
  target_compile_features(modular PUBLIC cxx_std_23)

  # Dependency providers and file API
  cmake_language(SET_DEPENDENCY_PROVIDER provide_dep SUPPORTED_METHODS FIND_PACKAGE FETCHCONTENT_MAKEAVAILABLE_SERIAL)
  cmake_language(GET_MESSAGE_LOG_LEVEL CURRENT_LEVEL)
  cmake_language(TRACE ENABLE) 
  cmake_language(EXIT 0)
  cmake_language(DEFER ID deferred_id CALL message "deferred message")
  cmake_language(DEFER CANCEL_CALL deferred_id)
  cmake_language(DEFER GET_CALL_IDS ids)
  cmake_instrumentation(API_VERSION 1 DATA_VERSION 1 HOOKS postBuild)

  # pkg-config, link-library features, runtime DLLs
  cmake_pkg_config(EXTRACT glib-2.0 REQUIRED)
  target_link_libraries(inventory PRIVATE
    "$<LINK_LIBRARY:WHOLE_ARCHIVE,archive_lib>"
    "$<LINK_LIBRARY:FRAMEWORK,Foundation>"
    "$<LINK_GROUP:RESCAN,a,b>"
    "$<COMPILE_ONLY:headers_only>"
    "$<LINK_ONLY:link_only>"
    "$<HOST_LINK:-Wl,--gc-sections>"
    "$<DEVICE_LINK:-arch=sm_80>"
    "$<TARGET_NAME_IF_EXISTS:optional_lib>")
  add_custom_command(TARGET inventory POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy -t $<TARGET_FILE_DIR:inventory> $<TARGET_RUNTIME_DLLS:inventory>
    COMMAND_EXPAND_LISTS
    VERBATIM)
  add_custom_command(OUTPUT generated.hpp COMMAND gen DEPENDS gen.in CODEGEN DEPFILE gen.d)
  add_custom_target(codegen_all DEPENDS generated.hpp JOB_POOL codegen_pool JOB_SERVER_AWARE TRUE)
  set_property(GLOBAL PROPERTY JOB_POOLS codegen_pool=2)

  # Generator expression families
  message("$<PATH:GET_FILENAME,/a/b/c.txt>" "$<PATH:REMOVE_EXTENSION,c.tar.gz,LAST_ONLY>"
          "$<PATH:APPEND,/a,b>" "$<PATH:CMAKE_PATH,NORMALIZE,/a/../b>" "$<PATH:IS_ABSOLUTE,/a>"
          "$<FILTER:a;b;c,INCLUDE,^a>" "$<REMOVE_DUPLICATES:a;a;b>" "$<LIST:TRANSFORM,a;b,TOUPPER>"
          "$<LIST:JOIN,a;b,->" "$<LIST:SORT,b;a>" "$<LIST:SUBLIST,a;b;c,1,1>" "$<LIST:FILTER,a;b,INCLUDE,a>"
          "$<IN_LIST:a,a;b>" "$<TARGET_EXISTS:inventory>" "$<TARGET_NAME:inventory>" "$<TARGET_LINKER_FILE:inventory>"
          "$<TARGET_SONAME_FILE:inventory>" "$<TARGET_BUNDLE_DIR:inventory>" "$<TARGET_IMPORT_FILE:inventory>"
          "$<TARGET_PDB_FILE:inventory>" "$<GENEX_EVAL:$<TARGET_PROPERTY:inventory,SRC>>"
          "$<CONFIG:Debug,Release>" "$<COMPILE_FEATURES:cxx_std_20>" "$<COMPILE_LANG_AND_ID:CXX,GNU,Clang>"
          "$<C_COMPILER_ID:GNU>" "$<CXX_COMPILER_VERSION>" "$<PLATFORM_ID:Linux,Darwin>" "$<HOST_SYSTEM_NAME>"
          "$<VERSION_LESS:1.2,1.10>" "$<VERSION_EQUAL:1.2,1.2>" "$<EQUAL:2,2>" "$<STREQUAL:a,a>" "$<STRING:TOLOWER,ABC>"
          "$<BOOL:ON>" "$<AND:1,1>" "$<OR:0,1>" "$<NOT:0>" "$<IF:1,yes,no>" "$<LOWER_CASE:ABC>" "$<MAKE_C_IDENTIFIER:a-b>"
          "$<DEVICE_LINK:x>" "$<TARGET_GENEX_EVAL:inventory,$<TARGET_PROPERTY:inventory,X>>"
          "$<INSTALL_PREFIX>" "$<OUTPUT_CONFIG:Release>" "$<CROSSCOMPILING_EMULATOR>" "$<LINK_LANGUAGE:C,CXX>"
          "$<SHELL_PATH:/a>" "$<QUOTE>" "$<ANGLE-R>" "$<COMMA>" "$<SEMICOLON>" "$<TARGET_POLICY:CMP0156>")

  # Newer conditionals
  if(DEFINED CACHE{MYVAR})
  elseif(PATH_EQUAL "/a/b" "/a/b/")
  elseif(TEST some_test)
  elseif(IS_READABLE "${CMAKE_SOURCE_DIR}" AND IS_WRITABLE "${CMAKE_BINARY_DIR}" AND IS_EXECUTABLE "/bin/sh")
  elseif(IS_SYMLINK "/tmp/link" OR IS_ABSOLUTE "/abs" OR IS_DIRECTORY "/tmp")
  elseif("a.txt" IS_NEWER_THAN "b.txt")
  elseif(1.2 VERSION_EQUAL 1.2.0 AND 1.2 VERSION_LESS 1.10 AND 2 VERSION_GREATER 1)
  elseif("x" MATCHES "^x" AND NOT "y" MATCHES "^x")
  elseif(DEFINED ENV{HOME} AND DEFINED CACHE{X} AND DEFINED VAR AND TARGET inventory AND TEST t AND COMMAND message)
  elseif(NOT (A OR B) AND (C OR (D AND E)))
  elseif(A EQUAL B OR A LESS_EQUAL B OR A GREATER_EQUAL B OR A STRLESS_EQUAL B OR A STRGREATER_EQUAL B)
  elseif(VAR_NAME)
  else()
  endif()

  # Block-scoped variables, return propagation, loop control
  block(SCOPE_FOR VARIABLES)
    set(only_here 1)
    set(only_parent 2 PARENT_SCOPE)
    return(PROPAGATE only_parent)
  endblock()
  block(PROPAGATE result)
    set(result done)
  endblock()
  foreach(item IN LISTS a b ITEMS c d)
    if(item STREQUAL "c")
      continue()
    endif()
  endforeach()
  foreach(k v IN ZIP_LISTS KEYS VALS)
  endforeach()
  foreach(i RANGE 10)
  endforeach()
  foreach(i RANGE 1 10 3)
  endforeach()

  # File, string, list, path and JSON operations from recent releases
  file(REAL_PATH "../x" RESOLVED BASE_DIRECTORY ${CMAKE_SOURCE_DIR} EXPAND_TILDE)
  file(CREATE_LINK a.txt b.txt SYMBOLIC)
  file(CHMOD a.txt PERMISSIONS OWNER_READ OWNER_WRITE)
  file(CHMOD_RECURSE dir FILE_PERMISSIONS OWNER_READ DIRECTORY_PERMISSIONS OWNER_EXECUTE)
  file(ARCHIVE_CREATE OUTPUT out.tar.zst PATHS a b FORMAT paxr COMPRESSION Zstd COMPRESSION_LEVEL 5)
  file(ARCHIVE_EXTRACT INPUT in.tar.gz DESTINATION out PATTERNS "*.txt" VERBOSE)
  file(GET_RUNTIME_DEPENDENCIES EXECUTABLES a.out RESOLVED_DEPENDENCIES_VAR resolved UNRESOLVED_DEPENDENCIES_VAR unresolved)
  file(SIZE a.txt SZ)
  file(TOUCH a.txt)
  file(TOUCH_NOCREATE a.txt)
  file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/gen)
  file(RENAME old new)
  file(REMOVE_RECURSE dir)
  file(READ_SYMLINK link target)
  file(TIMESTAMP a.txt TS "%Y-%m-%d" UTC)
  file(MD5 a.txt H)
  file(UPLOAD a.txt https://example.com/u USERPWD user:example-not-a-real-key)
  string(REPEAT "ab" 3 REPEATED)
  string(PREPEND VAR "head")
  string(SHA256 H "text")
  string(JSON RESULT ERROR_VARIABLE ERR SET "{}" key "\"value\"")
  string(JSON LEN LENGTH "[1,2,3]")
  string(JSON KINDS TYPE "{\"a\": null}" a)
  string(JSON EXISTS_VAR EXISTS "{\"a\":1}" a)
  string(JSON MEMBER_VAR MEMBER "{\"a\":1}" 0)
  string(JSON REMOVED REMOVE "{\"a\":1}" a)
  string(JSON ARR GET "{\"a\":[1]}" a)
  list(PREPEND LST first)
  list(POP_FRONT LST front)
  list(TRANSFORM LST APPEND "-x" AT 0 1)
  list(TRANSFORM LST REPLACE "a" "b")
  list(TRANSFORM LST STRIP)
  list(TRANSFORM LST GENEX_STRIP)
  list(SORT LST COMPARE NATURAL CASE INSENSITIVE ORDER DESCENDING)
  list(REMOVE_AT LST 0)
  list(REMOVE_ITEM LST x)
  list(CONTAINS LST x FOUND)
  cmake_path(RELATIVE_PATH P BASE_DIRECTORY /base OUTPUT_VARIABLE REL)
  cmake_path(ABSOLUTE_PATH P BASE_DIRECTORY /base NORMALIZE OUTPUT_VARIABLE ABS)
  cmake_path(CONVERT "a/b;c/d" TO_NATIVE_PATH_LIST NATIVE NORMALIZE)
  cmake_path(HAS_ROOT_NAME P HAS_NAME)
  cmake_path(COMPARE P1 EQUAL P2 SAME)
  cmake_path(HASH P HASHED)
  cmake_path(NATIVE_PATH P NORMALIZE NATIVE)
  cmake_path(REMOVE_FILENAME P)
  cmake_path(REMOVE_EXTENSION P LAST_ONLY)
  cmake_path(IS_PREFIX P1 P2 NORMALIZE PREFIXED)

  # Testing, packaging and presets-adjacent commands
  add_test(NAME t COMMAND prog)
  set_tests_properties(t PROPERTIES FIXTURES_REQUIRED setup RESOURCE_LOCK db TIMEOUT_AFTER_MATCH "30;ok" SKIP_RETURN_CODE 77)
  gtest_discover_tests(unit_tests DISCOVERY_MODE PRE_TEST PROPERTIES LABELS unit)
  include(GoogleTest)
  include(CTest)
  install(IMPORTED_RUNTIME_ARTIFACTS Foo::Foo RUNTIME_DEPENDENCY_SET deps DESTINATION lib)
  install(RUNTIME_DEPENDENCY_SET deps PRE_EXCLUDE_REGEXES "api-ms-" POST_EXCLUDE_REGEXES ".*system32/.*\\.dll")
  install(TARGETS inventory EXPORT InvTargets FILE_SET CXX_MODULES DESTINATION include/modules)
  install(EXPORT InvTargets NAMESPACE Inv:: CXX_MODULES_DIRECTORY cxx-modules DESTINATION lib/cmake/Inv)
  install(SCRIPT cleanup.cmake ALL_COMPONENTS)
  cpack_add_component(runtime DISPLAY_NAME "Runtime" REQUIRED)
  cpack_add_install_type(full DISPLAY_NAME "Full")

  # Properties and variables of the 3.x/4.x series
  set(CMAKE_COMPILE_WARNING_AS_ERROR ON)
  set(CMAKE_LINK_WARNING_AS_ERROR ON)
  set(CMAKE_OPTIMIZE_DEPENDENCIES ON)
  set(CMAKE_UNITY_BUILD ON)
  set(CMAKE_UNITY_BUILD_BATCH_SIZE 8)
  set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)
  set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
  set(CMAKE_MSVC_DEBUG_INFORMATION_FORMAT "$<$<CONFIG:Debug,RelWithDebInfo>:ProgramDatabase>")
  set(CMAKE_FIND_PACKAGE_TARGETS_GLOBAL ON)
  set(CMAKE_FIND_PACKAGE_PREFER_CONFIG ON)
  set(CMAKE_VERIFY_INTERFACE_HEADER_SETS ON)
  set(CMAKE_SKIP_INSTALL_ALL_DEPENDENCY ON)
  set(CMAKE_EXPERIMENTAL_CXX_IMPORT_STD "example-not-a-real-key")
  set_target_properties(inventory PROPERTIES
    CXX_MODULE_STD ON
    EXPORT_COMPILE_COMMANDS ON
    COMPILE_WARNING_AS_ERROR ON
    VERIFY_INTERFACE_HEADER_SETS ON
    CXX_SCAN_FOR_MODULES ON
    SYSTEM ON
    EXCLUDE_FROM_ALL OFF)
  set_source_files_properties(a.cpp PROPERTIES SKIP_LINTING ON LANGUAGE CXX COMPILE_OPTIONS "-O1;-g")
  set_directory_properties(PROPERTIES EXCLUDE_FROM_ALL OFF)

  # Legacy but still valid forms, labelled as such
  # deprecated: set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall")
  # deprecated: file(GLOB without CONFIGURE_DEPENDS)
  file(GLOB LEGACY_SOURCES "legacy/*.cpp")
  # deprecated: include_directories / add_definitions at directory scope
  include_directories(legacy)
  add_definitions(-DLEGACY_MODE)
endif()
