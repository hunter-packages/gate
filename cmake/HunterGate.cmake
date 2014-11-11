# Copyright (c) 2013-2014, Ruslan Baratov
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# This is a gate file to Hunter package manager.
# Usage: include this file using `include` command and add package you need:
#
#     include("cmake/HunterGate.cmake")
#     HunterGate(
#         URL "https://github.com/path/to/hunter/archive.tar.gz"
#         SHA1 "798501e983f14b28b10cda16afa4de69eee1da1d"
#     )
#     hunter_add_package(Foo)
#     hunter_add_package(Boo COMPONENTS Bar Baz)
#
# Projects:
#     * https://github.com/hunter-packages/gate/
#     * https://github.com/ruslo/hunter

cmake_minimum_required(VERSION 3.0)
include(CMakeParseArguments)

option(HUNTER_ENABLED "Enable Hunter package manager support" ON)

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

# If several processes simultaneously try to init base hunter directory
# this synchronisation helps to do it correctly
function(hunter_gate_try_lock result)
  if(NOT HUNTER_LOCK_PATH)
    message(FATAL_ERROR "Internal error (HUNTER_LOCK_PATH is empty)")
  endif()

  if(NOT HUNTER_LOCK_INFO)
    message(FATAL_ERROR "Internal error (HUNTER_LOCK_INFO is empty)")
  endif()

  if(NOT HUNTER_LOCK_FULL_INFO)
    message(FATAL_ERROR "Internal error (HUNTER_LOCK_FULL_INFO is empty)")
  endif()

  if(NOT PROJECT_BINARY_DIR)
    message(FATAL_ERROR "Internal error (PROJECT_BINARY_DIR is empty)")
  endif()

  file(TO_NATIVE_PATH "${HUNTER_LOCK_PATH}" lock_path)

  # `cmake -E make_directory` is not fit here because this command succeed
  # even if directory already exists
  if(WIN32)
    if(MINGW)
      # He-he :)
      string(REPLACE "/" "\\" lock_path "${lock_path}")
    endif()
    execute_process(
        COMMAND cmd /C mkdir "${lock_path}"
        RESULT_VARIABLE lock_result
        OUTPUT_VARIABLE lock_result_info
        ERROR_VARIABLE lock_result_info
    )
  else()
    execute_process(
        COMMAND mkdir "${lock_path}"
        RESULT_VARIABLE lock_result
        OUTPUT_VARIABLE lock_result_info
        ERROR_VARIABLE lock_result_info
    )
  endif()

  if(NOT lock_result EQUAL 0)
    message("Lock failed with result: ${lock_result}")
    message("Reason:  ${lock_result_info}")
    set(${result} FALSE PARENT_SCOPE)
    return()
  endif()

  file(WRITE "${HUNTER_LOCK_INFO}" "${PROJECT_BINARY_DIR}")

  string(TIMESTAMP time_now)
  file(
      WRITE
      "${HUNTER_LOCK_FULL_INFO}"
      "    Project binary directory: ${PROJECT_BINARY_DIR}\n"
      "    Build start at: ${time_now}"
  )

  set(${result} TRUE PARENT_SCOPE)
endfunction()

# Remove lock directory that created by `hunter_gate_try_lock`
function(hunter_gate_unlock)
  file(REMOVE_RECURSE "${HUNTER_LOCK_PATH}")

  # If failed pretend that we done.
  # Other projects will crash when check the
  # existance of `${HUNTER_SELF}/cmake/Hunter`
  file(WRITE "${HUNTER_GATE_INSTALL_DONE}" "done")
endfunction()

# Download project and unpack it to HUNTER_SELF
function(hunter_gate_do_download)
  if(NOT HUNTER_ROOT)
    message(FATAL_ERROR "Internal error (HUNTER_ROOT is empty)")
  endif()

  if(NOT HUNTER_SELF)
    message(FATAL_ERROR "Internal error (HUNTER_SELF is empty)")
  endif()

  if(NOT HUNTER_GATE_INSTALL_DONE)
    message(FATAL_ERROR "Internal error (HUNTER_GATE_INSTALL_DONE is empty)")
  endif()

  if(NOT HUNTER_LOCK_PATH)
    message(FATAL_ERROR "Internal error (HUNTER_LOCK_PATH is empty)")
  endif()

  if(NOT PROJECT_BINARY_DIR)
    message(
        FATAL_ERROR
        "PROJECT_BINARY_DIR is empty. "
        "Move HunterGate file **after** first project command"
    )
  endif()

  hunter_gate_try_lock(lock_successful)
  if(NOT lock_successful)
    # Return and wait until HUNTER_GATE_INSTALL_DONE created
    return()
  endif()

  set(TEMP_DIR "${PROJECT_BINARY_DIR}/_3rdParty/gate")
  set(TEMP_BUILD "${TEMP_DIR}/_builds")

  message(
      STATUS
      "[hunter] Hunter not found, start download to '${HUNTER_ROOT}' ..."
  )
  message(
      STATUS
      "[hunter] Temporary build directory: '${TEMP_BUILD}'"
  )

  # Disabling languages speeds up a little bit, reduces noise in the output
  # and avoids path too long windows error
  file(
      WRITE
      "${TEMP_DIR}/CMakeLists.txt"
      "cmake_minimum_required(VERSION 2.8.10)\n"
      "project(HunterDownload LANGUAGES NONE)\n"
      "include(ExternalProject)\n"
      "ExternalProject_Add(\n"
      "    Hunter\n"
      "    URL\n"
      "    \"${HUNTER_URL}\"\n"
      "    URL_HASH\n"
      "    SHA1=${HUNTER_SHA1}\n"
      "    DOWNLOAD_DIR\n"
      "    \"${HUNTER_ROOT}/_Base/Self-Downloads\"\n"
      "    SOURCE_DIR\n"
      "    \"${HUNTER_SELF}\"\n"
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
          "${CMAKE_COMMAND}"
          "-H${TEMP_DIR}"
          "-B${TEMP_BUILD}"
      WORKING_DIRECTORY "${TEMP_DIR}"
      RESULT_VARIABLE HUNTER_DOWNLOAD_RESULT
  )

  if(NOT HUNTER_DOWNLOAD_RESULT EQUAL 0)
    hunter_gate_unlock()
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
    hunter_gate_unlock()
    message(FATAL_ERROR "Build download project failed")
  endif()

  hunter_gate_unlock()

  message(STATUS "[hunter] downloaded to '${HUNTER_ROOT}'")
endfunction()

function(hunter_gate_init)
  if(NOT EXISTS "${HUNTER_SELF}")
    file(MAKE_DIRECTORY "${HUNTER_SELF}")
    if(NOT EXISTS "${HUNTER_SELF}")
      message(
          FATAL_ERROR
          "Can't create directory `${HUNTER_SELF}`"
          "(probably no permissions)"
      )
    endif()
    hunter_gate_do_download()
  endif()

  while(NOT EXISTS "${HUNTER_GATE_INSTALL_DONE}")
    # Directory already created, but installation is not finished yet
    if(EXISTS "${HUNTER_LOCK_FULL_INFO}")
      file(READ "${HUNTER_LOCK_FULL_INFO}" _fullinfo)
    else()
      set(_fullinfo "????")
    endif()
    string(TIMESTAMP _time_now)
    message(
        "[${_time_now}] Install already triggered, waiting for:\n${_fullinfo}\n"
        "If that build cancelled (interrupted by user or some other reason), "
        "please remove this directory manually:\n\n"
        "    ${HUNTER_LOCK_PATH}\n\n"
        "then run CMake again."
    )
    # Some sanity checks
    if(EXISTS "${HUNTER_LOCK_INFO}")
      file(READ "${HUNTER_LOCK_INFO}" _info)
      string(COMPARE EQUAL "${_info}" "${PROJECT_BINARY_DIR}" incorrect)
      if(incorrect)
        message(FATAL_ERROR "Waiting for self")
      endif()
      if(NOT EXISTS "${_info}")
        # Do not crash here, this may happens (checking/reading is not atomic)
        message("Waiting for deleted directory!")
      endif()
    endif()
    execute_process(COMMAND "${CMAKE_COMMAND}" -E sleep 1)
  endwhile()

  if(NOT EXISTS "${HUNTER_SELF}/cmake/Hunter")
    message(
        FATAL_ERROR
        "Internal error can't find master file in directory `${HUNTER_SELF}`"
    )
  endif()
endfunction()

macro(HunterGate)
  # If HUNTER_SHA1 or HUNTER_CONFIG_SHA1 is not in cache yet
  if(NOT HUNTER_SHA1 OR NOT HUNTER_CONFIG_SHA1)
    cmake_parse_arguments(HUNTER "LOCAL" "URL;SHA1;GLOBAL;FILEPATH" "" ${ARGV})
    if(NOT HUNTER_SHA1)
      message(FATAL_ERROR "SHA1 suboption of HunterGate is mandatory")
    endif()
    if(NOT HUNTER_URL)
      message(FATAL_ERROR "URL suboption of HunterGate is mandatory")
    endif()
    if(HUNTER_UNPARSED_ARGUMENTS)
      message(FATAL_ERROR "HunterGate unparsed arguments")
    endif()
    if(HUNTER_GLOBAL)
      if(HUNTER_LOCAL)
        message(FATAL_ERROR "Unexpected LOCAL (already has GLOBAL)")
      endif()
      if(HUNTER_FILEPATH)
        message(FATAL_ERROR "Unexpected FILEPATH (already has GLOBAL)")
      endif()
    endif()
    if(HUNTER_LOCAL)
      if(HUNTER_GLOBAL)
        message(FATAL_ERROR "Unexpected GLOBAL (already has LOCAL)")
      endif()
      if(HUNTER_FILEPATH)
        message(FATAL_ERROR "Unexpected FILEPATH (already has LOCAL)")
      endif()
    endif()
    if(HUNTER_FILEPATH)
      if(HUNTER_GLOBAL)
        message(FATAL_ERROR "Unexpected GLOBAL (already has FILEPATH)")
      endif()
      if(HUNTER_LOCAL)
        message(FATAL_ERROR "Unexpected LOCAL (already has FILEPATH)")
      endif()
    endif()
  endif()

  hunter_gate_detect_root() # set HUNTER_ROOT and HUNTER_ROOT_INFO

  if(NOT HUNTER_ROOT)
    message(FATAL_ERROR "Internal error: HUNTER_ROOT is not set")
  endif()

  # Beautify path, fix probable problems with windows path slashes
  get_filename_component(HUNTER_ROOT "${HUNTER_ROOT}" ABSOLUTE)

  if(EXISTS "${HUNTER_ROOT}/cmake/Hunter")
    # hunter installed manually
    set(HUNTER_SHA1 "")
    set(HUNTER_SHA1_SHORT "")
    set(HUNTER_URL "")
    set(HUNTER_SELF "${HUNTER_ROOT}")
    set(HUNTER_GATE_INSTALL_DONE "${HUNTER_ROOT}/_Base")
    file(MAKE_DIRECTORY "${HUNTER_ROOT}/_Base")
  else()
    string(SUBSTRING "${HUNTER_SHA1}" 0 7 HUNTER_SHA1_SHORT)
    set(HUNTER_SELF "${HUNTER_ROOT}/_Base/${HUNTER_SHA1_SHORT}/Self")
    set(HUNTER_GATE_INSTALL_DONE "${HUNTER_SELF}/../install-gate-done")
  endif()

  set(HUNTER_URL "${HUNTER_URL}" CACHE STRING "Hunter archive URL")
  set(HUNTER_SHA1 "${HUNTER_SHA1}" CACHE STRING "Hunter archive SHA1 hash")
  set(
      HUNTER_SHA1_SHORT
      "${HUNTER_SHA1_SHORT}"
      CACHE
      STRING
      "Hunter archive SHA1 hash (short)"
  )

  # Beautify path, fix probable problems with windows path slashes
  get_filename_component(HUNTER_SELF "${HUNTER_SELF}" ABSOLUTE)

  set(HUNTER_ROOT "${HUNTER_ROOT}" CACHE PATH "Hunter root directory")
  set(HUNTER_SELF "${HUNTER_SELF}" CACHE PATH "Hunter self directory")

  if(NOT HUNTER_CONFIG_SHA1)
    if(HUNTER_GLOBAL)
      set(HUNTER_CONFIG "${HUNTER_SELF}/cmake/configs/${HUNTER_GLOBAL}.cmake")
    elseif(HUNTER_LOCAL)
      set(HUNTER_CONFIG "${CMAKE_CURRENT_LIST_DIR}/cmake/Hunter/config.cmake")
    elseif(HUNTER_FILEPATH)
      set(HUNTER_CONFIG "${HUNTER_FILEPATH}")
    else()
      set(HUNTER_CONFIG "${HUNTER_SELF}/cmake/configs/default.cmake")
    endif()
  endif()

  set(HUNTER_LOCK_PATH "${HUNTER_SELF}/../directory-lock")
  set(HUNTER_LOCK_INFO "${HUNTER_LOCK_PATH}/info")
  set(HUNTER_LOCK_FULL_INFO "${HUNTER_LOCK_PATH}/fullinfo")

  if(HUNTER_ENABLED)
    hunter_gate_init()

    # HUNTER_SELF found or downloaded if not exists, i.e. can be used now
    include("${HUNTER_SELF}/cmake/Hunter")
    if(NOT HUNTER_CONFIG_SHA1)
      message(FATAL_ERROR "Internal error: HUNTER_CONFIG_SHA1 is empty")
    endif()
    if(NOT HUNTER_BASE)
      message(FATAL_ERROR "Internal error: HUNTER_BASE is empty")
    endif()

    include(hunter_status_debug)
    hunter_status_debug("${HUNTER_ROOT_INFO}")

    include(hunter_add_package)
  else()
    # Empty function to avoid error "unknown function"
    function(hunter_add_package)
    endfunction()
  endif()
endmacro()
