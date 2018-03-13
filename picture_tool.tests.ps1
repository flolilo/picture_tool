# Comment out the last block of picture_tool (i.e. "Start-up") before running this script!
# Maybe also comment out write-colorout function.

# DEFINITION: Get all error-outputs in English:
    [Threading.Thread]::CurrentThread.CurrentUICulture = 'en-US'
# DEFINITION: Hopefully avoiding errors by wrong encoding now:
    $OutputEncoding = New-Object -typename System.Text.UTF8Encoding
    [Console]::OutputEncoding = New-Object -typename System.Text.UTF8Encoding

. $PSScriptRoot\picture_tool.ps1



<# DONE:    Describe "Test-EXEPaths" {
            $BlaDrive = "$TestDrive\TEST"
            New-Item -ItemType Directory -Path $BlaDrive
            Push-Location $BlaDrive
            Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x -aoa -bb0 -pdefault -sccUTF-8 -spf2 `"$($PSScriptRoot)\picture_tool_TESTFILES.7z`" `"-o.\`" " -WindowStyle Minimized -Wait
            Pop-Location

            BeforeEach {
                [hashtable]$UserParams = @{
                    EXIFtool=   "$BlaDrive\exiftool.exe"
                    Magick =    "$BlaDrive\ImageMagick\magick.exe"
                    ConvertQuality = 92
                }
            }

            Context "Basics" {
                It "Throw if no/wrong param" {
                    {Test-EXEPaths} | Should Throw
                    {Test-EXEPaths -UserParams 123} | Should Throw
                    {Test-EXEPaths -UserParams @{}} | Should Throw
                }
                It "Return false if no tools are found" {
                    $UserParams.EXIFtool = "$BlaDrive\noexiftool.exe"
                    $UserParams.Magick = "$BlaDrive\nomagick.exe"
                    $test = Test-EXEPaths -UserParams $UserParams
                    $test | Should Be $false

                    $UserParams.EXIFtool = "$BlaDrive\exiftool.exe"
                    $test = Test-EXEPaths -UserParams $UserParams
                    $test | Should Be $false

                    $UserParams.EXIFtool = "$BlaDrive\noexiftool.exe"
                    $UserParams.Magick = "$BlaDrive\magick.exe"
                    $test = Test-EXEPaths -UserParams $UserParams
                    $test | Should Be $false
                }
                It "Return hashtable if all is correct" {
                    $test = Test-EXEPaths -UserParams $UserParams
                    $test | Should BeOfType hashtable
                    $test.ConvertQuality | Should Be 92
                }
            }
            Context "No problems with SpecChars" {
                It "12345" {
                    $UserParams.EXIFtool = "$BlaDrive\123456789 ordner\123412356789 exiftool.exe"
                    $test = Test-EXEPaths -UserParams $UserParams
                    $test | Should BeOfType hashtable
                    $test.ConvertQuality | Should Be 92
                }
                It "Æ" {
                    $UserParams.EXIFtool = "$BlaDrive\ÆOrdner\Æexiftool.exe"
                    $test = Test-EXEPaths -UserParams $UserParams
                    $test | Should BeOfType hashtable
                    $test.ConvertQuality | Should Be 92
                }
                It "backtick" {
                    $UserParams.EXIFtool = "$BlaDrive\backtick ````ordner ``\backtick ````exiftool ``.exe"
                    $test = Test-EXEPaths -UserParams $UserParams
                    $test | Should BeOfType hashtable
                    $test.ConvertQuality | Should Be 92
                }
                It "bracket" {
                    $UserParams.EXIFtool = "$BlaDrive\bracket [ ] ordner\bracket [ ] exiftool.exe"
                    $test = Test-EXEPaths -UserParams $UserParams
                    $test | Should BeOfType hashtable
                    $test.ConvertQuality | Should Be 92
                }
                It "dots" {
                    $UserParams.EXIFtool = "$BlaDrive\ordner.mit.punkten\exif.tool.exe"
                    $test = Test-EXEPaths -UserParams $UserParams
                    $test | Should BeOfType hashtable
                    $test.ConvertQuality | Should Be 92
                }
                It "specials" {
                    $UserParams.EXIFtool = "$BlaDrive\special ' ! ,; . ordner\special ' ! ,; . exiftool.exe"
                    $test = Test-EXEPaths -UserParams $UserParams
                    $test | Should BeOfType hashtable
                    $test.ConvertQuality | Should Be 92
                }
            }
        }
#>

Describe "Get-InputFiles" {
    $BlaDrive = "$TestDrive\TEST"
    New-Item -ItemType Directory -Path $BlaDrive
    Push-Location $BlaDrive
    Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x -aoa -bb0 -pdefault -sccUTF-8 -spf2 `"$($PSScriptRoot)\picture_tool_TESTFILES.7z`" `"-o.\`" " -WindowStyle Minimized -Wait
    Pop-Location

    BeforeEach {
        [hashtable]$UserParams = @{
            InputPath =             @("$BlaDrive")
            Convert2JPEG =          1
            EXIFManipulation =      1
            EXIFDeleteAll =         0
            EXIFAddCopyright =      0
            EXIFPresetName =        "default"
            EXIFArtistName =        ""
            EXIFCopyrightText =     ""
            Formats =               @("*.jpeg","*.jpg")
            ConvertQuality =        92
            ConvertRemoveSource =   1
            Convert2SRGB =          0
            ConvertScaling =        100
            EXIFtool=               "$BlaDrive\exiftool.exe"
            Magick =                "$BlaDrive\ImageMagick\magick.exe"
            MagickThreads =         12
        }
    }

    Context "Basics" {
        It "Throw if no/wrong param" {
            {Get-InputFiles} | Should Throw
            {Get-InputFiles -UserParams 123} | Should Throw
            {Get-InputFiles -UserParams @{}} | Should Throw
        }
        It "Return array if all is well" {
            $test = @(Get-InputFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 9
        }
        It "Return array even with one item" {
            $UserParams.Formats = @("*.png")
            $test = @(Get-InputFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.SourceName | Should Be "123412356789 file_PNG.png"
        }
        It "Trailing backslash does not concern the program" {
            $UserParams.InputPath = @("$BlaDrive\")
            $test = @(Get-InputFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 9
        }
        It "Get multiple folders" {
            $UserParams.InputPath = @("$BlaDrive","$BlaDrive\123456789 ordner")
            $test = @(Get-InputFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 18
        }
        It "Get single file" {
            $UserParams.InputPath = @("$BlaDrive\123412356789 file.jpg")
            $test = @(Get-InputFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 1
        }
        It "Get multiple files" {
            $UserParams.InputPath = @("$BlaDrive\123412356789 file.jpg","$BlaDrive\file.with.dots.jpg")
            $test = @(Get-InputFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 2
        }
        It "Get mixed content" {
            $UserParams.InputPath = @("$BlaDrive","$BlaDrive\123412356789 file.jpg")
            $test = @(Get-InputFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 10
        }
    }
    Context "No problems with SpecChars" {
        It "12345" {
            $UserParams.InputPath = "$BlaDrive\123456789 ordner"
            $test = Test-EXEPaths -UserParams $UserParams
            $test | Should BeOfType hashtable
            $test.ConvertQuality | Should Be 92
        }
        It "Æ" {
            $UserParams.InputPath = "$BlaDrive\ÆOrdner"
            $test = Test-EXEPaths -UserParams $UserParams
            $test | Should BeOfType hashtable
            $test.ConvertQuality | Should Be 92
        }
        It "backtick" {
            $UserParams.EXIFtool = "$BlaDrive\backtick ````ordner ``\backtick ````exiftool ``.exe"
            $UserParams.Magick = "$BlaDrive\backtick ````ordner ``\ImageMagick\backtick ````magick ``.exe"
            $test = Test-EXEPaths -UserParams $UserParams
            $test | Should BeOfType hashtable
            $test.ConvertQuality | Should Be 92
        }
        It "bracket" {
            $UserParams.EXIFtool = "$BlaDrive\bracket [ ] ordner\bracket [ ] exiftool.exe"
            $UserParams.Magick = "$BlaDrive\bracket [ ] ordner\ImageMagick\bracket [ ] magick.exe"
            $test = Test-EXEPaths -UserParams $UserParams
            $test | Should BeOfType hashtable
            $test.ConvertQuality | Should Be 92
        }
        It "dots" {
            $UserParams.EXIFtool = "$BlaDrive\ordner.mit.punkten\exif.tool.exe"
            $UserParams.Magick = "$BlaDrive\ordner.mit.punkten\ImageMagick\ma.gick.exe"
            $test = Test-EXEPaths -UserParams $UserParams
            $test | Should BeOfType hashtable
            $test.ConvertQuality | Should Be 92
        }
        It "specials" {
            $UserParams.EXIFtool = "$BlaDrive\special ' ! ,; . ordner\special ' ! ,; . exiftool.exe"
            $UserParams.Magick = "$BlaDrive\special ' ! ,; . ordner\ImageMagick\special ' ! ,; . magick.exe"
            $test = Test-EXEPaths -UserParams $UserParams
            $test | Should BeOfType hashtable
            $test.ConvertQuality | Should Be 92
        }
    }
}

<#
    # DEFINITION: Convert from XYZ to JPEG:
    Describe "Start-Converting" {
    }

    # DEFINITION: Get EXIF values from JSON or console:
    Describe "Get-EXIFValues" {
    }

    # DEFINITION: EXIF manipulation (transfer / modify):
    Describe "Start-EXIFManipulation" {
    }

    # DEFINITION: Recycle:
    Describe "Start-Recycling" {
    }

    # DEFINITION: Start everything:
    Describe "Start-Everything" {
    }
#>