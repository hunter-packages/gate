# Copyright (c) 2013-2014, Ruslan Baratov
# All rights reserved.

# This is a gate file to Hunter package manager.
# Usage: include this file using `include` command and add package you need:
#
#     include("cmake/HunterGate.cmake")
#     hunter_add_package(Foo)
#     hunter_add_package(Boo COMPONENTS Bar Baz)
#
# Projects:
#     * https://github.com/hunter-packages/gate/
#     * https://github.com/ruslo/hunter

cmake_minimum_required(VERSION 2.8.10)
include(CMakeParseArguments)

macro(HunterGate)
  cmake_parse_arguments(HUNTER "" "URL;SHA1" "" ${ARGV})
  if(HUNTER_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "HunterGate unparsed arguments")
  endif()
  set(HUNTER_URL "${HUNTER_URL}" CACHE STRING "Hunter archive URL")
  set(HUNTER_SHA1 "${HUNTER_SHA1}" CACHE STRING "Hunter archive SHA1 hash")
endmacro()

# 01.
# Customizable --
HunterGate(
    URL "https://github.com/ruslo/hunter/archive/multiversion-test-01.tar.gz"
    SHA1 "798501e983f14b28b10cda16afa4de69eee1da1d"
)
# -- end

# Set HUNTER_ROOT cmake variable to suitable value.
# Info about variable can be found in HUNTER_ROOT_INFO.
function(hunter_gate_detect_root)
  # Check CMake variable
  if(HUNTER_ROOT)
    set(HUNTER_ROOT_INFO "HUNTER_ROOT detected by cmake variable" PARENT_SCOPE)
    return()
  endif()

  # Check environment variable
  string(COMPARE NOTEQUAL "$ENV{HUNTER_ROOT}" "" not_empty)
  if(not_empty)
    set(HUNTER_ROOT "$ENV{HUNTER_ROOT}" PARENT_SCOPE)
    set(
        HUNTER_ROOT_INFO
        "HUNTER_ROOT detected by environment variable"
        PARENT_SCOPE
    )
    return()
  endif()

  # Check HOME environment variable
  string(COMPARE NOTEQUAL "$ENV{HOME}" "" result)
  if(result)
    set(HUNTER_ROOT "$ENV{HOME}/HunterPackages" PARENT_SCOPE)
    set(
        HUNTER_ROOT_INFO
        "HUNTER_ROOT set using HOME environment variable"
        PARENT_SCOPE
    )
    return()
  endif()

  # Check PROGRAMFILES environment variable (windows only)
  if(WIN32)
    string(COMPARE NOTEQUAL "$ENV{PROGRAMFILES}" "" result)
    if(result)
      set(HUNTER_ROOT "$ENV{PROGRAMFILES}/HunterPackages" PARENT_SCOPE)
      set(
          HUNTER_ROOT_INFO
          "HUNTER_ROOT set using PROGRAMFILES environment variable"
          PARENT_SCOPE
      )
      return()
    endif()
  endif()

  # Create in project
  if(NOT PROJECT_SOURCE_DIR)
     message(FATAL_ERROR "PROJECT_SOURCE_DIR is empty")
  endif()

  set(HUNTER_ROOT "${PROJECT_SOURCE_DIR}/HunterPackages" PARENT_SCOPE)
  set(
      HUNTER_ROOT_INFO
      "HUNTER_ROOT set by project sources directory"
      PARENT_SCOPE
  )
endfunction()

# Download project to HUNTER_ROOT
function(hunter_gate_do_download)
  if(NOT HUNTER_BASE)
    message(FATAL_ERROR "Internal error (HUNTER_BASE empty)")
  endif()

  message(
      STATUS
      "[hunter] Hunter not found, start download to '${HUNTER_BASE}' ..."
  )

  if(NOT PROJECT_BINARY_DIR)
    message(
        FATAL_ERROR
        "PROJECT_BINARY_DIR is empty. "
        "Move HunterGate file **after** first project command"
    )
  endif()

  set(TEMP_DIR "${PROJECT_BINARY_DIR}/_3rdParty/gate")
  set(TEMP_BUILD "${TEMP_DIR}/_builds")

  file(
      WRITE
      "${TEMP_DIR}/CMakeLists.txt"
      "cmake_minimum_required(VERSION 2.8.10)\n"
      "include(ExternalProject)\n"
      "ExternalProject_Add(\n"
      "    Hunter\n"
      "    URL\n"
      "    \"${HUNTER_URL}\"\n"
      "    URL_HASH\n"
      "    SHA1=${HUNTER_SHA1}\n"
      "    DOWNLOAD_DIR\n"
      "    \"${HUNTER_BASE}/Download\"\n"
      "    SOURCE_DIR\n"
      "    \"${HUNTER_BASE}/Self\"\n"
      "    CONFIGURE_COMMAND\n"
      "    \"\"\n"
      "    BUILD_COMMAND\n"
      "    \"\"\n"
      "    INSTALL_COMMAND\n"
      "    \"\"\n"
      ")\n"
  )

  execute_process(
      COMMAND
      "${CMAKE_COMMAND}" "-H${TEMP_DIR}" "-B${TEMP_BUILD}"
      WORKING_DIRECTORY
      "${TEMP_DIR}"
      RESULT_VARIABLE
      HUNTER_DOWNLOAD_RESULT
  )

  if(NOT HUNTER_DOWNLOAD_RESULT EQUAL 0)
    message(FATAL_ERROR "Configure download project failed")
  endif()

  execute_process(
      COMMAND
      "${CMAKE_COMMAND}" --build "${TEMP_BUILD}"
      WORKING_DIRECTORY
      "${TEMP_DIR}"
      RESULT_VARIABLE
      HUNTER_DOWNLOAD_RESULT
  )

  if(NOT HUNTER_DOWNLOAD_RESULT EQUAL 0)
    message(FATAL_ERROR "Build download project failed")
  endif()

  message(STATUS "[hunter] downloaded to '${HUNTER_BASE}'")
endfunction()

# 02.
hunter_gate_detect_root() # set HUNTER_ROOT and HUNTER_ROOT_INFO

# 03.
if(NOT HUNTER_ROOT)
  message(FATAL_ERROR "Internal error: HUNTER_ROOT is not set")
endif()

set(HUNTER_BASE "${HUNTER_ROOT}/_Base/${HUNTER_SHA1}")

# Beautify path, fix probable problems with windows path slashes
get_filename_component(HUNTER_ROOT "${HUNTER_ROOT}" ABSOLUTE)
get_filename_component(HUNTER_BASE "${HUNTER_BASE}" ABSOLUTE)

set(HUNTER_ROOT "${HUNTER_ROOT}" CACHE PATH "Hunter root directory")
set(HUNTER_BASE "${HUNTER_BASE}" CACHE PATH "Hunter base directory")

if(NOT EXISTS "${HUNTER_BASE}")
  # 04.
  hunter_gate_do_download()
endif()

if(NOT EXISTS "${HUNTER_BASE}/Self/cmake/Hunter")
  message(
      FATAL_ERROR
      "Internal error can't find master file in directory `${HUNTER_BASE}`"
  )
endif()

# 11.
# HUNTER_BASE found or downloaded if not exists, i.e. can be used now
include("${HUNTER_BASE}/Self/cmake/Hunter")

include(hunter_status_debug)
hunter_status_debug("${HUNTER_ROOT_INFO}")

include(hunter_add_package)
