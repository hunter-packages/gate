| Linux/OSX                                       | Windows                                             |
|-------------------------------------------------|-----------------------------------------------------|
| [![Build Status][travis_status]][travis_builds] | [![Build Status][appveyor_status]][appveyor_builds] |

[travis_status]: https://travis-ci.org/hunter-packages/gate.png?branch=master
[travis_builds]: https://travis-ci.org/hunter-packages/gate

[appveyor_status]: https://ci.appveyor.com/api/projects/status/nmkbcuoxwre7w2jp/branch/master?svg=true
[appveyor_builds]: https://ci.appveyor.com/project/ruslo/gate/branch/master

This is a gate file to [Hunter](https://github.com/ruslo/hunter) package manager.

## Usage

* Copy file `HunterGate.cmake` to project
* Include gate file: `include("cmake/HunterGate.cmake")`
* Put any valid [Hunter](https://github.com/ruslo/hunter/releases) archive with `SHA1` hash:
```cmake
HunterGate(
    URL "https://github.com/ruslo/hunter/archive/v0.7.0.tar.gz"
    SHA1 "e730118c7ec65126398f8d4f09daf9366791ede0"
)
```

## Usage (custom config)

Optionally custom [config.cmake][1] file can be specified. File may has different locations:

* `GLOBAL`. The one from Hunter archive:
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

* [Example](https://github.com/ruslo/hunter/wiki/example.custom.config.id)

### Notes

* If you're in process of patching Hunter and have a HUNTER_ROOT pointed to git repository location then HunterGate will not use `URL` and `SHA1` values. It means when you update `SHA1` of Hunter archive new commits/fixes will not be applied at all. In this case you have to update your git repo manually (i.e. do `git pull`)
* You don't need to specify [hunter_config][2] command for all projects. Set version of the package you're interested in - others will be used from default `config.cmake`.
* If you want to get full control of what Hunter-SHA1 root directories you want to auto-install you can set [HUNTER_DISABLE_AUTOINSTALL](https://github.com/ruslo/hunter/wiki/CMake-Variables-%28User%29#hunter_disable_autoinstall-environment-variable) environment variable and use [HUNTER_RUN_INSTALL=YES](https://github.com/ruslo/hunter/wiki/CMake-Variables-%28User%29#hunter_run_install) CMake variable to allow installations explicitly.

## Effects
* Try to detect `Hunter`:
 * test CMake variable `HUNTER_ROOT` (control, shared downloads and builds)
 * test environment variable `HUNTER_ROOT` (**recommended**: control, shared downloads and builds)
 * test directory `${HOME}/.hunter` (shared downloads and builds)
 * test directory `${SYSTEMDRIVE}/.hunter` (shared downloads and builds, windows only)
 * test directory `${USERPROFILE}/.hunter` (shared downloads and builds, windows only)
* Set `HUNTER_GATE_*` variables
* Include Hunter master file `include("${HUNTER_SELF}/cmake/Hunter")`

## Flowchart (for developers)
![flowchart](https://raw.githubusercontent.com/hunter-packages/gate/master/wiki/flowchart.png)

## Examples
* [This](https://github.com/hunter-packages/gate/blob/master/CMakeLists.txt)
* [Simple](https://github.com/forexample/hunter-simple)
* [Weather](https://github.com/ruslo/weather)

## Links
* [Hunter](https://github.com/ruslo/hunter)
* [Some packages](https://github.com/ruslo/hunter/wiki/Packages)

[1]: https://github.com/ruslo/hunter/blob/master/cmake/configs/default.cmake
[2]: https://github.com/ruslo/hunter/wiki/Hunter-modules#hunter_config
