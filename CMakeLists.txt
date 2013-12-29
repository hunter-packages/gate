# Copyright (c) 2013, Ruslan Baratov
# All rights reserved.

cmake_minimum_required(VERSION 2.8.10)
project(gate-usage-example)

# 1. Try to detect hunter by:
#   * cmake variable
#   * environment variable
#   * in HOME (HunterPackages directory)
#   * in current source dir (HunterPackages directory)
# 2. if failed, download it
# 3. set HUNTER_ROOT to point to result directory
# 4. include master file: 'include(${HUNTER_ROOT}/Source/cmake/Hunter)
# 5. include `hunter_add_package` module
include("HunterGate.cmake")

# now hunter can be used, like
hunter_add_package(Sugar)

# add downloaded package to project
include("${SUGAR_ROOT}/cmake/Sugar")
include(sugar_status_print)

# use downloaded package
set(SUGAR_STATUS_PRINT ON CACHE BOOL "")
sugar_status_print("Hello!")
