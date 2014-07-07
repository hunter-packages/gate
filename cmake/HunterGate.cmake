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
  cmake_parse_arguments(HUNTER_MINIMUM "" "URL;SHA1" "" ${ARGV})
endmacro()

# 01.
# Customizable --
HunterGate(
    URL "https://github.com/ruslo/hunter/archive/v0.4.2.tar.gz"
    SHA1 "3a6c66670dc4103ff2567c03d44b2a99e288e3c8"
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
  message(
      STATUS
      "[hunter] Hunter not found, start download to '${HUNTER_ROOT}' ..."
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
      "    \"${HUNTER_MINIMUM_URL}\"\n"
      "    URL_HASH\n"
      "    SHA1=${HUNTER_MINIMUM_SHA1}\n"
      "    DOWNLOAD_DIR\n"
      "    \"${HUNTER_ROOT}/Download\"\n"
      "    SOURCE_DIR\n"
      "    \"${HUNTER_ROOT}/Source\"\n"
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

  message(STATUS "[hunter] downloaded to '${HUNTER_ROOT}'")
endfunction()

# 02.
hunter_gate_detect_root() # set HUNTER_ROOT and HUNTER_ROOT_INFO

# 03.
if(NOT HUNTER_ROOT)
  message(
      FATAL_ERROR
      "Internal error in 'hunter_gate_detect_root': HUNTER_ROOT is not set"
  )
endif()

# Beautify path, fix probable problems with windows path slashes
get_filename_component(HUNTER_ROOT "${HUNTER_ROOT}" ABSOLUTE)

if(NOT EXISTS "${HUNTER_ROOT}")
  # 04.
  hunter_gate_do_download()
  if(NOT EXISTS "${HUNTER_ROOT}")
    message(
        FATAL_ERROR
        "Internal error in 'hunter_gate_do_download': "
        "directory HUNTER_ROOT not found"
    )
  endif()
endif()

# 05.

# at this point: HUNTER_ROOT exists (is file or directory)
if(NOT IS_DIRECTORY "${HUNTER_ROOT}")
  message(
      FATAL_ERROR
      "HUNTER_ROOT is not directory (${HUNTER_ROOT})"
      "(${HUNTER_ROOT_INFO})"
  )
endif()

# at this point: HUNTER_ROOT exists and is directory
file(GLOB _hunter_result "${HUNTER_ROOT}/*")
list(LENGTH _hunter_result _hunter_result_len)
if(_hunter_result_len EQUAL 0)
  # 06.
  # HUNTER_ROOT directory is empty, let's download it
  hunter_gate_do_download()
endif()

unset(_hunter_result)
unset(_hunter_result_len)

# 11.
# HUNTER_ROOT found or downloaded if not exists, i.e. can be used now
include("${HUNTER_ROOT}/Source/cmake/Hunter")

include(hunter_status_debug)
hunter_status_debug(
    "${HUNTER_ROOT_INFO}"
)

include(hunter_add_package)
