This is a gate file to [hunter](https://github.com/ruslo/hunter) package manager.

## Usage

* copy two files to project: `cmake/{HunterGate.cmake, HunterDownload.cmake.in}`
* include gate file: `include("./cmake/HunterGate.cmake")`

## Effects
* Try to detect `hunter`:
 * test environment variable `HUNTER_ROOT`
 * test cmake variable `HUNTER_ROOT`
 * test directory `${HOME}/HunterPackages`
 * test directory `HunterPackages` in current project sources
* If not detected - download it using `HunterDownload.cmake.in` script and set `HUNTER_ROOT` variable
* Include hunter master file: `include("${HUNTER_ROOT}/cmake/Hunter")`

On success this message will be printed:
```
[hunter] HUNTER_ROOT: /home/travis/HunterPackages
```
