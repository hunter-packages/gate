# Copyright (c) 2013-2014, Ruslan Baratov
# All rights reserved.

cmake_minimum_required(VERSION 3.0)
project(gate-usage-example)

include("cmake/HunterGate.cmake")

# 1. Try to detect hunter by:
#   * cmake variable
#   * environment variable
#   * in HOME (HunterPackages directory)
#   * in PROGRAMFILES (HunterPackages directory, windows only)
#   * in current source dir (HunterPackages directory)
# 2. if failed, download it
# 3. set HUNTER_ROOT, HUNTER_BASE, HUNTER_SELF to point to result directory
# 4. include master file: 'include(${HUNTER_SELF}/cmake/Hunter)
# 5. include `hunter_add_package` module
HunterGate(
    URL "https://github.com/ruslo/hunter/archive/v0.5.12.tar.gz"
    SHA1 "a807daa0f6439db605744fb736d32757a07c9407"
)

# now hunter can be used, like
hunter_add_package(Sugar)

# add downloaded package to project
include("${SUGAR_ROOT}/cmake/Sugar")
include(sugar_status_print)

# use downloaded package
set(SUGAR_STATUS_PRINT ON CACHE BOOL "")
sugar_status_print("Hello!")
