| linux                                     | macosx                                    |
|-------------------------------------------|-------------------------------------------|
| [![Build Status][link_master]][link_gate] | [![Build Status][link_macosx]][link_gate] |


[link_master]: https://travis-ci.org/hunter-packages/gate.png?branch=master
[link_macosx]: https://travis-ci.org/hunter-packages/gate.png?branch=travis.macosx
[link_gate]: https://travis-ci.org/hunter-packages/gate

This is a gate file to [hunter](https://github.com/ruslo/hunter) package manager.

## Usage

* Copy file `HunterGate.cmake` to project
* Include gate file: `include("cmake/HunterGate.cmake")`
* Put any valid [hunter](https://github.com/ruslo/hunter/releases) archive with `SHA1` hash:
```cmake
HunterGate(
    URL "https://github.com/ruslo/hunter/archive/v0.7.0.tar.gz"
    SHA1 "e730118c7ec65126398f8d4f09daf9366791ede0"
)
```

## Usage (custom config)

Optionally custom [config.cmake][1] file can be specified. File may has different locations:

* `GLOBAL`. The one from hunter archive:
```cmake
HunterGate(
    URL "https://github.com/ruslo/hunter/archive/v0.7.0.tar.gz"
    SHA1 "e730118c7ec65126398f8d4f09daf9366791ede0"
    GLOBAL myconfig
        # load `${HUNTER_SELF}/cmake/configs/myconfig.cmake` instead of
        # default `${HUNTER_SELF}/cmake/configs/default.cmake`
)
```
* `LOCAL`. Default local config.
```cmake
HunterGate(
    URL "https://github.com/ruslo/hunter/archive/v0.7.0.tar.gz"
    SHA1 "e730118c7ec65126398f8d4f09daf9366791ede0"
    LOCAL # load `${CMAKE_CURRENT_LIST_DIR}/cmake/Hunter/config.cmake`
)
```
* `FILEPATH`. Any location.
```cmake
HunterGate(
    URL "https://github.com/ruslo/hunter/archive/v0.7.0.tar.gz"
    SHA1 "e730118c7ec65126398f8d4f09daf9366791ede0"
    FILEPATH "/any/path/to/config.cmake"
)
```

### Notes

* You don't need to specify [hunter_config][2] command for all projects. Set version of the package you're interested in - others will be used from default `config.cmake`.
* If Hunter root directory is empty you need to set [HUNTER_RUN_INSTALL=YES](https://github.com/ruslo/hunter/wiki/CMake-Variables-%28User%29#hunter_run_install) on first run and HunterGate will automatically download it

## Effects
* Try to detect `hunter`:
 * test cmake variable `HUNTER_ROOT` (control, shared downloads and builds)
 * test environment variable `HUNTER_ROOT` (**recommended**: control, shared downloads and builds)
 * test directory `${HOME}/.hunter` (shared downloads and builds)
 * test directory `${SYSTEMDRIVE}/.hunter` (shared downloads and builds, windows only)
 * test directory `${USERPROFILE}/.hunter` (shared downloads and builds, windows only)
* Set `HUNTER_GATE_*` variables
* Include hunter master file `include("${HUNTER_SELF}/cmake/Hunter")`

## Examples
* [This](https://github.com/hunter-packages/gate/blob/master/CMakeLists.txt)
* [Simple](https://github.com/forexample/hunter-simple)
* [Weather](https://github.com/ruslo/weather)

## Links
* [Hunter](https://github.com/ruslo/hunter)
* [Some packages](https://github.com/ruslo/hunter/wiki/Packages)

[1]: https://github.com/ruslo/hunter/blob/master/cmake/configs/default.cmake
[2]: https://github.com/ruslo/hunter/wiki/Hunter-modules#hunter_config
