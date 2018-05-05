# Changelog

All notable changes to this project will be documented in this file.


## 3.4.2 - 2018-05-05
### Changed
 - Increased speed of exiftool's argument-creation (swapped `for` and `if`)
 - Removed `$debuginter` and filled in its value into the corresponding `Write-Colorout`s.
 - Renamed `$ArgList` to `$magickArgList` and `$exiftoolArgList`, so I can properly search for them.


## 3.4.1 - 2018-05-04
### Changed
 - `-EXIFManipulation` (exiftool) would stop after doing more than 114 files. Now output buffer is read asynchronously.


## 3.4 - 2018-03-28
### Added
- 4:4:4 chroma subsampling in all quality settings for converting - also, progressively saved files.
- Included `-EXIFtoolFailSafe` in the pester-test.
- Included bit depth and interlacing in test.


## 3.3 - 2018-03-19
### Added
 - Parameter `-EXIFtoolFailSafe` - pre-run Exiftool. Exiftool tends to fail when being run for the first time with commands ([see Note b with installing the standalone executable](https://www.sno.phy.queensu.ca/~phil/exiftool/install.html)), so now it will have time to get cracking.


## 3.2 - 2018-03-17
 - **Up to this version, I did not keep track of particular changes.**

### Changed
 - The whole code in a manner so that it now will withstand a unit-test.
