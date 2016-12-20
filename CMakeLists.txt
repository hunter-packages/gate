# Copyright (c) 2013-2014, Ruslan Baratov
# All rights reserved.

cmake_minimum_required(VERSION 3.0)

include("cmake/HunterGate.cmake")

# 1. Try to detect hunter by:
#   * cmake variable
#   * environment variable
#   * in HOME (`.hunter` directory)
#   * in SYSTEMDRIVE (`.hunter` directory, windows only)
#   * in USERPROFILE (`.hunter` directory, windows only)
# 2. if failed, download it
# 3. set HUNTER_GATE_* variables
# 4. include master file: 'include(${HUNTER_SELF}/cmake/Hunter)
HunterGate(
    URL "https://github.com/ruslo/hunter/archive/v0.17.3.tar.gz"
    SHA1 "2a2f193860e2cb3b884bce74d85c3f30b1092274"
)

project(gate-usage-example)

# now hunter can be used, like
hunter_add_package(Sugar)

# add downloaded package to project
include("${SUGAR_ROOT}/cmake/Sugar")
include(sugar_status_print)

# use downloaded package
set(SUGAR_STATUS_PRINT ON CACHE BOOL "")
sugar_status_print("Hello!")
