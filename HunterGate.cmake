# Copyright (c) 2013, Ruslan Baratov
# All rights reserved.

cmake_minimum_required(VERSION 2.8.10)

set(HUNTER_MINIMUM_VERSION "0.1.0")
set(HUNTER_MINIMUM_VERSION_HASH 92576d39b925651a63ca356e0416b981ff795f26)

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

  set(URL_BASE "https://github.com/ruslo/hunter/archive")
  file(
      WRITE
      "${PROJECT_BINARY_DIR}/Hunter-prefix/CMakeLists.txt"
      "cmake_minimum_required(VERSION 2.8.10)\n"
      "include(ExternalProject)\n"
      "ExternalProject_Add(\n"
      "    Hunter\n"
      "    URL\n"
      "    \"${URL_BASE}/v${HUNTER_MINIMUM_VERSION}.tar.gz\"\n"
      "    URL_HASH\n"
      "    SHA1=${HUNTER_MINIMUM_VERSION_HASH}\n"
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
      "${CMAKE_COMMAND}" .
      WORKING_DIRECTORY
      "${PROJECT_BINARY_DIR}/Hunter-prefix"
      RESULT_VARIABLE
      HUNTER_DOWNLOAD_RESULT
  )

  if(NOT HUNTER_DOWNLOAD_RESULT EQUAL 0)
    message(FATAL_ERROR "Configure download project failed")
  endif()

  execute_process(
      COMMAND
      "${CMAKE_COMMAND}" --build .
      WORKING_DIRECTORY
      "${PROJECT_BINARY_DIR}/Hunter-prefix"
      RESULT_VARIABLE
      HUNTER_DOWNLOAD_RESULT
  )

  if(NOT HUNTER_DOWNLOAD_RESULT EQUAL 0)
    message(FATAL_ERROR "Build download project failed")
  endif()

  message(STATUS "[hunter] downloaded to '${HUNTER_ROOT}'")
endfunction()

hunter_gate_detect_root() # set HUNTER_ROOT and HUNTER_ROOT_INFO

if(NOT HUNTER_ROOT)
  message(
      FATAL_ERROR
      "Internal error in 'hunter_gate_detect_root': HUNTER_ROOT is not setted"
  )
endif()

if(NOT EXISTS "${HUNTER_ROOT}")
  hunter_gate_do_download()
  if(NOT EXISTS "${HUNTER_ROOT}")
    message(
        FATAL_ERROR
        "Internal error in 'hunter_gate_do_download': "
        "directory HUNTER_ROOT not found"
    )
  endif()
endif()

# at this point: HUNTER_ROOT exists and is file or directory
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
  # HUNTER_ROOT directory is empty, let's download it
  hunter_gate_do_download()
endif()

# at this point: HUNTER_ROOT exists and is not empty directory
if(NOT EXISTS "${HUNTER_ROOT}/Source/cmake/Hunter")
  message(
      FATAL_ERROR
      "HUNTER_ROOT directory exists (${HUNTER_ROOT})"
      "but '${HUNTER_ROOT}/Source/cmake/Hunter' file not found"
      "(${HUNTER_ROOT_INFO})"
  )
endif()

# HUNTER_ROOT found or downloaded if not exists, i.e. can be used now
include("${HUNTER_ROOT}/Source/cmake/Hunter")

include(hunter_status_debug)
hunter_status_debug("${HUNTER_ROOT_INFO}")

include(hunter_add_package)
