# Copyright (c) 2013, Ruslan Baratov
# All rights reserved.

cmake_minimum_required(VERSION 2.8.10)

if(NOT "--$ENV{HUNTER_ROOT}__" STREQUAL "--__")
  # Hunter detected by environment
  if(NOT EXISTS "$ENV{HUNTER_ROOT}/cmake/Hunter")
    message(
        FATAL_ERROR
        "HUNTER_ROOT(environment): '$ENV{HUNTER_ROOT}'\n"
        "but no file '$ENV{HUNTER_ROOT}/cmake/Hunter'"
    )
  endif()
  set(HUNTER_ROOT "$ENV{HUNTER_ROOT}")
  message(STATUS "[hunter] detected by environment variable: '${HUNTER_ROOT}'")
  include("${HUNTER_ROOT}/cmake/Hunter")
  return()
endif()

if(NOT "--${HUNTER_ROOT}__" STREQUAL "--__")
  # Hunter detected by cmake variable
  if(NOT EXISTS "${HUNTER_ROOT}/cmake/Hunter")
    message(
        FATAL_ERROR
        "HUNTER_ROOT(cmake): '${HUNTER_ROOT}'"
        "but no file '${HUNTER_ROOT}/cmake/Hunter'"
    )
  endif()
  message(STATUS "[hunter] detected by cmake variable: '${HUNTER_ROOT}'")
  include("${HUNTER_ROOT}/cmake/Hunter")
  return()
endif()

if(NOT "--$ENV{HOME}__" STREQUAL "--__")
  set(HUNTER_ROOT "$ENV{HOME}/HunterPackages")
  if(EXISTS "${HUNTER_ROOT}")
    if(NOT EXISTS "${HUNTER_ROOT}/cmake/Hunter")
      message(
          FATAL_ERROR
          "HunterPackages found in '${HUNTER_ROOT}', "
          "but '${HUNTER_ROOT}/cmake/Hunter' not exists. "
          "Please remove '${HUNTER_ROOT}'."
      )
    endif()
    message(STATUS "[hunter] detected in HOME(environment): '${HUNTER_ROOT}'")
    include("${HUNTER_ROOT}/cmake/Hunter")
    return()
  endif()
endif()

if(EXISTS "${PROJECT_SOURCE_DIR}/HunterPackages")
  set(HUNTER_ROOT "${PROJECT_SOURCE_DIR}/HunterPackages")
  if(NOT EXISTS "${HUNTER_ROOT}/cmake/Hunter")
    message(
        FATAL_ERROR
        "HunterPackages found in '${HUNTER_ROOT}', "
        "but '${HUNTER_ROOT}/cmake/Hunter' not exists. "
        "Please remove '${HUNTER_ROOT}'."
    )
  endif()
  message(STATUS "[hunter] detected in current project: '${HUNTER_ROOT}'")
  include("${HUNTER_ROOT}/cmake/Hunter")
  return()
endif()

# Not found, need to download
if(NOT "--$ENV{HOME}__" STREQUAL "--__")
  set(HUNTER_ROOT "$ENV{HOME}/HunterPackages")
else()
  if(NOT PROJECT_SOURCE_DIR)
    message(FATAL_ERROR "PROJECT_SOURCE_DIR is empty")
  endif()
  set(HUNTER_ROOT "${PROJECT_SOURCE_DIR}/HunterPackages")
endif()

message(
    STATUS
    "[hunter] Hunter not found, start download to '${HUNTER_ROOT}' ..."
)

configure_file(
    "${CMAKE_CURRENT_LIST_DIR}/HunterDownload.cmake.in"
    "${PROJECT_BINARY_DIR}/Hunter-prefix/CMakeLists.txt"
    @ONLY
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

if(EXISTS "${HUNTER_ROOT}/cmake/Hunter")
  include("${HUNTER_ROOT}/cmake/Hunter")
else()
  message(FATAL_ERROR "Download failed")
endif()
