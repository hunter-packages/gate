| linux                                     | macosx                                    |
|-------------------------------------------|-------------------------------------------|
| [![Build Status][link_master]][link_gate] | [![Build Status][link_macosx]][link_gate] |


[link_master]: https://travis-ci.org/hunter-packages/gate.png?branch=master
[link_macosx]: https://travis-ci.org/hunter-packages/gate.png?branch=travis.macosx
[link_gate]: https://travis-ci.org/hunter-packages/gate

This is a gate file to [hunter](https://github.com/ruslo/hunter) package manager.

## Usage

* copy file `HunterGate.cmake` to project
* include gate file: `include("HunterGate.cmake")`

## Effects
* Try to detect `hunter`:
 * test cmake variable `HUNTER_ROOT` (control, shared downloads and builds)
 * test environment variable `HUNTER_ROOT` (**recommended**: control, shared downloads and builds)
 * test directory `${HOME}/HunterPackages` (shared downloads and builds)
 * test directory `HunterPackages` in current project sources (**not** recommended: no share, local downloads and builds)
* If not detected - download it and set `HUNTER_ROOT` variable
* Include hunter master file `include("${HUNTER_ROOT}/Source/cmake/Hunter")`
* Include `hunter_add_package` module with corresponding function

On success this message will be printed:
```
-- [hunter] HUNTER_ROOT: /home/travis/HunterPackages
```

## Example
* https://github.com/hunter-packages/gate/blob/master/CMakeLists.txt
