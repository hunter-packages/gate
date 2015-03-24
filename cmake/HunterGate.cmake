# Copyright (c) 2013-2015, Ruslan Baratov
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

cmake_minimum_required(VERSION 3.0) # Minimum for Hunter
include(CMakeParseArguments) # cmake_parse_arguments

option(HUNTER_ENABLED "Enable Hunter package manager support" ON)
option(HUNTER_STATUS_PRINT "Print working status" ON)
option(HUNTER_STATUS_DEBUG "Print a lot info" OFF)

set(HUNTER_WIKI "https://github.com/ruslo/hunter/wiki")

function(hunter_gate_status_print)
  foreach(print_message ${ARGV})
    if(HUNTER_STATUS_PRINT OR HUNTER_STATUS_DEBUG)
      message(STATUS "[hunter] ${print_message}")
    endif()
  endforeach()
endfunction()

function(hunter_gate_status_debug)
  foreach(print_message ${ARGV})
    if(HUNTER_STATUS_DEBUG)
      message(STATUS "[hunter *** DEBUG ***] ${print_message}")
    endif()
  endforeach()
endfunction()

function(hunter_gate_wiki wiki_page)
  message("------------------------------ WIKI -------------------------------")
  message("    ${HUNTER_WIKI}/${wiki_page}")
  message("-------------------------------------------------------------------")
  message("")
  message(FATAL_ERROR "")
endfunction()

function(hunter_gate_internal_error)
  message("")
  foreach(print_message ${ARGV})
    message("[hunter ** INTERNAL **] ${print_message}")
  endforeach()
  message("[hunter ** INTERNAL **] [Directory:${CMAKE_CURRENT_LIST_DIR}]")
  message("")
  hunter_gate_wiki("error.internal")
endfunction()

function(hunter_gate_fatal_error)
  cmake_parse_arguments(hunter "" "WIKI" "" "${ARGV}")
  if(NOT hunter_WIKI)
    hunter_gate_internal_error("Expected wiki")
  endif()
  message("")
  foreach(x ${hunter_UNPARSED_ARGUMENTS})
    message("[hunter ** FATAL ERROR **] ${x}")
  endforeach()
  message("[hunter ** FATAL ERROR **] [Directory:${CMAKE_CURRENT_LIST_DIR}]")
  message("")
  hunter_gate_wiki("${hunter_WIKI}")
endfunction()

function(hunter_gate_user_error)
  hunter_gate_fatal_error(${ARGV} WIKI "error.incorrect.input.data")
endfunction()

# Set HUNTER_CACHED_ROOT_NEW cmake variable to suitable value.
function(hunter_gate_detect_root)
  # Check CMake variable
  if(HUNTER_ROOT)
    set(HUNTER_CACHED_ROOT_NEW "${HUNTER_ROOT}" PARENT_SCOPE)
    hunter_gate_status_debug("HUNTER_ROOT detected by cmake variable")
    return()
  endif()

  # Check environment variable
  string(COMPARE NOTEQUAL "$ENV{HUNTER_ROOT}" "" not_empty)
  if(not_empty)
    set(HUNTER_CACHED_ROOT_NEW "$ENV{HUNTER_ROOT}" PARENT_SCOPE)
    hunter_gate_status_debug("HUNTER_ROOT detected by environment variable")
    return()
  endif()

  # Check HOME environment variable
  string(COMPARE NOTEQUAL "$ENV{HOME}" "" result)
  if(result)
    set(HUNTER_CACHED_ROOT_NEW "$ENV{HOME}/HunterPackages" PARENT_SCOPE)
    hunter_gate_status_debug("HUNTER_ROOT set using HOME environment variable")
    return()
  endif()

  # Check PROGRAMFILES environment variable (windows only)
  if(WIN32)
    string(COMPARE NOTEQUAL "$ENV{PROGRAMFILES}" "" result)
    if(result)
      set(
          HUNTER_CACHED_ROOT_NEW
          "$ENV{PROGRAMFILES}/HunterPackages"
          PARENT_SCOPE
      )
      hunter_gate_status_debug(
          "HUNTER_ROOT set using PROGRAMFILES environment variable"
      )
      return()
    endif()
  endif()

  hunter_gate_internal_error("Can't detect HUNTER_ROOT")
endfunction()

macro(hunter_gate_lock dir)
  if(NOT HUNTER_SKIP_LOCK)
    if("${CMAKE_VERSION}" VERSION_LESS "3.2")
      hunter_gate_fatal_error(
          "Can't lock, upgrade to CMake 3.2 or use HUNTER_SKIP_LOCK"
          WIKI "error.can.not.lock"
      )
    endif()
    file(LOCK "${dir}" DIRECTORY GUARD FUNCTION)
  endif()
endmacro()

function(hunter_gate_download dir)
  string(COMPARE EQUAL "${dir}" "" is_bad)
  if(is_bad)
    hunter_gate_internal_error("Empty 'dir' argument")
  endif()

  string(COMPARE EQUAL "${HUNTER_GATE_SHA1}" "" is_bad)
  if(is_bad)
    hunter_gate_internal_error("HUNTER_GATE_SHA1 empty")
  endif()

  string(COMPARE EQUAL "${HUNTER_GATE_URL}" "" is_bad)
  if(is_bad)
    hunter_gate_internal_error("HUNTER_GATE_URL empty")
  endif()

  set(done_location "${dir}/DONE")
  set(sha1_location "${dir}/SHA1")

  set(build_dir "${dir}/Build")
  set(cmakelists "${dir}/CMakeLists.txt")
  file(REMOVE_RECURSE "${build_dir}")
  file(REMOVE_RECURSE "${cmakelists}")

  file(MAKE_DIRECTORY "${build_dir}") # check directory permissions

  hunter_gate_lock("${dir}")
  if(EXISTS "${done_location}")
    # while waiting for lock other instance can do all the job
    return()
  endif()

  # Disabling languages speeds up a little bit, reduces noise in the output
  # and avoids path too long windows error
  file(
      WRITE
      "${cmakelists}"
      "cmake_minimum_required(VERSION 3.0)\n"
      "project(HunterDownload LANGUAGES NONE)\n"
      "include(ExternalProject)\n"
      "ExternalProject_Add(\n"
      "    Hunter\n"
      "    URL\n"
      "    \"${HUNTER_GATE_URL}\"\n"
      "    URL_HASH\n"
      "    SHA1=${HUNTER_GATE_SHA1}\n"
      "    DOWNLOAD_DIR\n"
      "    \"${dir}\"\n"
      "    SOURCE_DIR\n"
      "    \"${dir}/Unpacked\"\n"
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
          "-H${dir}"
          "-B${build_dir}"
      WORKING_DIRECTORY "${dir}"
      RESULT_VARIABLE download_result
  )

  if(NOT download_result EQUAL 0)
    hunter_gate_internal_error("Configure project failed")
  endif()

  execute_process(
      COMMAND
      "${CMAKE_COMMAND}" --build "${build_dir}"
      WORKING_DIRECTORY "${dir}"
      RESULT_VARIABLE download_result
  )

  if(NOT download_result EQUAL 0)
    hunter_gate_internal_error("Build project failed")
  endif()

  file(REMOVE_RECURSE "${build_dir}")
  file(REMOVE_RECURSE "${cmakelists}")

  file(WRITE "${sha1_location}" "${HUNTER_GATE_SHA1}")
  file(WRITE "${done_location}" "DONE")
endfunction()

function(HunterGate)
  if(NOT HUNTER_ENABLED)
    # Empty function to avoid error "unknown function"
    function(hunter_add_package)
    endfunction()
    return()
  endif()

  # First HunterGate command will init Hunter, others will be ignored
  get_property(hunter_gate_done GLOBAL PROPERTY HUNTER_GATE_DONE SET)
  if(hunter_gate_done)
    return()
  endif()
  set_property(GLOBAL PROPERTY HUNTER_GATE_DONE YES)

  if(PROJECT_NAME)
    hunter_gate_fatal_error(
        "Please set HunterGate *before* 'project' command"
        WIKI "error.huntergate.before.project"
    )
  endif()

  cmake_parse_arguments(
      HUNTER_GATE "LOCAL" "URL;SHA1;GLOBAL;FILEPATH" "" ${ARGV}
  )
  if(NOT HUNTER_GATE_SHA1)
    hunter_gate_user_error("SHA1 suboption of HunterGate is mandatory")
  endif()
  if(NOT HUNTER_GATE_URL)
    hunter_gate_user_error("URL suboption of HunterGate is mandatory")
  endif()
  if(HUNTER_GATE_UNPARSED_ARGUMENTS)
    hunter_gate_user_error(
        "HunterGate unparsed arguments: ${HUNTER_GATE_UNPARSED_ARGUMENTS}"
    )
  endif()
  if(HUNTER_GATE_GLOBAL)
    if(HUNTER_GATE_LOCAL)
      hunter_gate_user_error("Unexpected LOCAL (already has GLOBAL)")
    endif()
    if(HUNTER_GATE_FILEPATH)
      hunter_gate_user_error("Unexpected FILEPATH (already has GLOBAL)")
    endif()
  endif()
  if(HUNTER_GATE_LOCAL)
    if(HUNTER_GATE_GLOBAL)
      hunter_gate_user_error("Unexpected GLOBAL (already has LOCAL)")
    endif()
    if(HUNTER_GATE_FILEPATH)
      hunter_gate_user_error("Unexpected FILEPATH (already has LOCAL)")
    endif()
  endif()
  if(HUNTER_GATE_FILEPATH)
    if(HUNTER_GATE_GLOBAL)
      hunter_gate_user_error("Unexpected GLOBAL (already has FILEPATH)")
    endif()
    if(HUNTER_GATE_LOCAL)
      hunter_gate_user_error("Unexpected LOCAL (already has FILEPATH)")
    endif()
  endif()

  hunter_gate_detect_root() # set HUNTER_CACHED_ROOT_NEW

  # Beautify path, fix probable problems with windows path slashes
  get_filename_component(
      HUNTER_CACHED_ROOT_NEW "${HUNTER_CACHED_ROOT_NEW}" ABSOLUTE
  )

  set(master_location "${HUNTER_CACHED_ROOT_NEW}/cmake/Hunter")
  if(EXISTS "${master_location}")
    # Hunter downloaded manually (e.g. 'git clone')
    include("${master_location}")
    return()
  endif()

  string(
      REGEX
      MATCH
      "[0-9]+\\.[0-9]+\\.[0-9]+[-_a-z0-9]*"
      url_version
      "${HUNTER_GATE_URL}"
  )
  string(COMPARE EQUAL "${url_version}" "" is_empty)
  if(is_empty)
    set(url_version "unknown")
  endif()
  set(
      archive_id_location
      "${HUNTER_CACHED_ROOT_NEW}/_Base/Download/Hunter/${url_version}"
  )

  string(SUBSTRING "${HUNTER_GATE_SHA1}" 0 7 ARCHIVE_ID)
  set(archive_id_location "${archive_id_location}/${ARCHIVE_ID}")

  set(done_location "${archive_id_location}/DONE")
  set(sha1_location "${archive_id_location}/SHA1")
  set(HUNTER_SELF "${archive_id_location}/Unpacked")
  set(master_location "${HUNTER_SELF}/cmake/Hunter")

  if(NOT EXISTS "${done_location}")
    hunter_gate_download("${archive_id_location}")
  endif()

  if(NOT EXISTS "${done_location}")
    hunter_gate_internal_error("hunter_gate_download failed")
  endif()

  if(NOT EXISTS "${sha1_location}")
    hunter_gate_internal_error("${sha1_location} not found")
  endif()
  file(READ "${sha1_location}" sha1_value)
  string(COMPARE EQUAL "${sha1_value}" "${HUNTER_GATE_SHA1}" is_equal)
  if(NOT is_equal)
    hunter_gate_internal_error(
        "Short SHA1 collision:\n"
        "  ${sha1_value} (from ${sha1_location})\n"
        "  ${HUNTER_GATE_SHA1} (HunterGate)"
    )
  endif()
  if(NOT EXISTS "${master_location}")
    hunter_gate_user_error(
        "Master file not found: ${master_location}\n"
        "(try to update Hunter/HunterGate)"
    )
  endif()
  include("${master_location}")
endfunction()
