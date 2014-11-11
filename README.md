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
```
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
```
HunterGate(
    URL "https://github.com/ruslo/hunter/archive/v0.7.0.tar.gz"
    SHA1 "e730118c7ec65126398f8d4f09daf9366791ede0"
    LOCAL # load `${CMAKE_CURRENT_LIST_DIR}/cmake/Hunter/config.cmake`
)
```
* `FILEPATH`. Any location.
```
HunterGate(
    URL "https://github.com/ruslo/hunter/archive/v0.7.0.tar.gz"
    SHA1 "e730118c7ec65126398f8d4f09daf9366791ede0"
    FILEPATH "/any/path/to/config.cmake"
)
```

### Notes

* Note that locations of libraries in `HUNTER_ROOT` directory depends on `config.cmake` => changes of `config.cmake` will be applied **only after clearing cache**. This is similar to work of `find_package` command. Even if it will be allowed to change `config.cmake` file on-the-fly, cached `find_package` variables will not change and new paths will not be applied.

* You don't need to specify [hunter_config][2] command for all projects. Set version of the package you're interested in - others will be used from default `config.cmake`.

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

[1]: https://github.com/ruslo/hunter/blob/master/cmake/config.cmake
[2]: https://github.com/ruslo/hunter/wiki/Hunter-modules#hunter_config
