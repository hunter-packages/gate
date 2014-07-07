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
* Put any valid [hunter](https://github.com/ruslo/hunter/releases) archive with sha1 hash:
```
HunterGate(
    URL "https://github.com/ruslo/hunter/archive/v0.4.1.tar.gz"
    SHA1 "f46f105449f6c78e729f866237038b70d03ebcc8"
)
```

## Effects
* Try to detect `hunter`:
 * test cmake variable `HUNTER_ROOT` (control, shared downloads and builds)
 * test environment variable `HUNTER_ROOT` (**recommended**: control, shared downloads and builds)
 * test directory `${HOME}/HunterPackages` (shared downloads and builds)
 * test directory `${PROGRAMFILES}/HunterPackages` (shared downloads and builds, windows only)
 * test directory `HunterPackages` in current project sources (**not** recommended: no share, local downloads and builds)
* If not detected - download it and set `HUNTER_ROOT`, `HUNTER_BASE`, `HUNTER_SELF` variables
* Include hunter master file `include("${HUNTER_SELF}/cmake/Hunter")`
* Include `hunter_add_package` module with corresponding function

On success this message will be printed:
```
-- [hunter] HUNTER_ROOT: /home/travis/HunterPackages
-- [hunter] HUNTER_SELF: /home/travis/HunterPackages/_Base/f46f105449f6c78e729f866237038b70d03ebcc8/Self
```

## Examples
* [This](https://github.com/hunter-packages/gate/blob/master/CMakeLists.txt)
* [Simple](https://github.com/forexample/hunter-simple)
* [Weather](https://github.com/ruslo/weather)

## Links
* [Hunter](https://github.com/ruslo/hunter)
* [Some packages](https://github.com/ruslo/hunter/wiki/Packages)
