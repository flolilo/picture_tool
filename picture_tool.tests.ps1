# Comment out the last block of picture_tool (i.e. "Start-up") before running this script!
# Maybe also comment out write-colorout function.

# DEFINITION: Get all error-outputs in English:
    [Threading.Thread]::CurrentThread.CurrentUICulture = 'en-US'
# DEFINITION: Hopefully avoiding errors by wrong encoding now:
    $OutputEncoding = New-Object -typename System.Text.UTF8Encoding
    [Console]::OutputEncoding = New-Object -typename System.Text.UTF8Encoding

. $PSScriptRoot\picture_tool.ps1

Describe "Test-EXEPaths" {
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
            EXIFTransferOnly =      0
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
            EXIFtoolFailSafe =      1
            MagickThreads =         12
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

            $UserParams.Convert2JPEG =          1
            $UserParams.EXIFManipulation =      0
            $UserParams.EXIFtool=               "$BlaDrive\noexiftool.exe"
            $UserParams.Magick =                "$BlaDrive\ImageMagick\magick.exe"
            $test = Test-EXEPaths -UserParams $UserParams
            $test | Should BeOfType hashtable
            $test.ConvertQuality | Should Be 92

            $UserParams.Convert2JPEG =          0
            $UserParams.EXIFManipulation =      1
            $UserParams.EXIFtool=               "$BlaDrive\exiftool.exe"
            $UserParams.Magick =                "$BlaDrive\ImageMagick\nomagick.exe"
            $test = Test-EXEPaths -UserParams $UserParams
            $test | Should BeOfType hashtable
            $test.ConvertQuality | Should Be 92
        }
    }
    Context "No problems with SpecChars" {
        BeforeEach {
            $UserParams.EXIFtoolFailSafe = 0
        }
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
        It "©" {
            $UserParams.EXIFtool = "$BlaDrive\©Ordner\©exiftool.exe"
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
            EXIFTransferOnly =      0
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
            $test.Length | Should Be 10
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
            $test.Length | Should Be 10
        }
        It "Get multiple folders" {
            $UserParams.InputPath = @("$BlaDrive","$BlaDrive\123456789 ordner")
            $test = @(Get-InputFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 20
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
            $test.Length | Should Be 11
        }
        It "Non-existing files/folders work" {
            $UserParams.InputPath = @("$BlaDrive\nofile.jpg")
            $test = @(Get-InputFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 0

            $UserParams.InputPath = @("$BlaDrive\nofolder")
            $test = @(Get-InputFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 0

            $UserParams.InputPath = @("$BlaDrive\nofolder","$BlaDrive\nofile.jpg")
            $test = @(Get-InputFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 0
        }
    }
    Context "No problems with SpecChars" {
        It "12345" {
            $UserParams.InputPath = @("$BlaDrive\123456789 ordner")
            $test = @(Get-InputFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 10
        }
        It "Æ" {
            $UserParams.InputPath = @("$BlaDrive\ÆOrdner")
            $test = @(Get-InputFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 10
        }
        It "©" {
            $UserParams.EXIFtool = "$BlaDrive\©Ordner"
            $test = @(Get-InputFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 10
        }
        It "backtick" {
            $UserParams.InputPath = @("$BlaDrive\backtick ````ordner ``")
            $test = @(Get-InputFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 10
        }
        It "bracket" {
            $UserParams.InputPath = @("$BlaDrive\bracket [ ] ordner")
            $test = @(Get-InputFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 10
        }
        It "dots" {
            $UserParams.InputPath = @("$BlaDrive\ordner.mit.punkten")
            $test = @(Get-InputFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 10
        }
        It "specials" {
            $UserParams.InputPath = @("$BlaDrive\special ' ! ,; . ordner")
            $test = @(Get-InputFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 10
        }
    }
}

Describe "Start-Converting" {
    $BlaDrive = "$TestDrive\TEST"
    New-Item -ItemType Directory -Path $BlaDrive
    Push-Location $BlaDrive
    Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x -aoa -bb0 -pdefault -sccUTF-8 -spf2 `"$($PSScriptRoot)\picture_tool_TESTFILES.7z`" `"-o.\`" " -WindowStyle Minimized -Wait
    Pop-Location

    BeforeEach {
        [hashtable]$UserParams = @{
            InputPath =             @("$BlaDrive")
            Convert2JPEG =          1
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
            {Start-Converting} | Should Throw
            {Start-Converting -UserParams 123} | Should Throw
            {Start-Converting -UserParams @{}} | Should Throw
            {Start-Converting -WorkingFiles $WorkingFiles} | Should Throw
            {Start-Converting -UserParams $UserParams} | Should Throw
            {Start-Converting -UserParams $UserParams -WorkingFiles @()} | Should Throw
        }
        It "Return no errors if all goes well" {
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $test = Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0
            (Get-ChildItem -LiteralPath "$($UserParams.InputPath)\" -Filter $UserParams.Formats[1]).count | Should Be 20
            $bla = (Get-InputFiles -UserParams $UserParams).SourceFullName
            $bla | ForEach-Object {
                if($WorkingFiles.SourceFullName -notcontains $_){
                    Remove-Item -LiteralPath $_
                }
            }
        }
        It "Work with all settings" {
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $UserParams.Convert2SRGB =      1
            $UserParams.ConvertQuality =    10
            $UserParams.ConvertScaling =    10
            $test = Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0
            Push-Location $BlaDrive
            foreach($i in $WorkingFiles.JPEGFullName){
                $meta = @()
                $meta = @(.\exiftool.exe "$i" -All:All -J | ConvertFrom-Json)
                $meta.EncodingProcess   | Should Be "Progressive DCT, Huffman coding"
                # TODO: does not yet show up with test-files...
                # $meta.YCbCrSubSampling  | Should Be "YCbCr4:4:4 (1 1)"
                $meta.BitsPerSample     | Should Be "8"
            }
            Pop-Location
            (Get-ChildItem -LiteralPath "$($UserParams.InputPath)\" -Filter $UserParams.Formats[1]).count | Should Be 20
            $bla = (Get-InputFiles -UserParams $UserParams).SourceFullName
            $bla | ForEach-Object {
                if($WorkingFiles.SourceFullName -notcontains $_){
                    Remove-Item -LiteralPath $_
                }
            }
        }
        It "Return 1 if error is encountered" {
            Mock Start-Process {throw}
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $test = Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 10
            Assert-MockCalled Start-Process -Times 9
        }
    }
    Context "No problems with SpecChars" {
        It "12345" {
            $UserParams.InputPath = @("$BlaDrive\123456789 ordner")
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $test = Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0
            (Get-ChildItem -LiteralPath "$($UserParams.InputPath)\" -Filter $UserParams.Formats[1]).count | Should Be 20
        }
        It "Æ" {
            $UserParams.InputPath = @("$BlaDrive\ÆOrdner")
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $test = Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0
            (Get-ChildItem -LiteralPath "$($UserParams.InputPath)\" -Filter $UserParams.Formats[1]).count | Should Be 20
        }
        It "©" {
            $UserParams.InputPath = @("$BlaDrive\©Ordner")
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $test = Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0
            (Get-ChildItem -LiteralPath "$($UserParams.InputPath)\" -Filter $UserParams.Formats[1]).count | Should Be 20
        }
        It "backtick" {
            $UserParams.InputPath = @("$BlaDrive\backtick ````ordner ``")
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $test = Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0
            (Get-ChildItem -LiteralPath "$($UserParams.InputPath)\" -Filter $UserParams.Formats[1]).count | Should Be 20
        }
        It "bracket" {
            $UserParams.InputPath = @("$BlaDrive\bracket [ ] ordner")
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $test = Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0
            (Get-ChildItem -LiteralPath "$($UserParams.InputPath)\" -Filter $UserParams.Formats[1]).count | Should Be 20
        }
        It "dots" {
            $UserParams.InputPath = @("$BlaDrive\ordner.mit.punkten")
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $test = Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0
            (Get-ChildItem -LiteralPath "$($UserParams.InputPath)\" -Filter $UserParams.Formats[1]).count | Should Be 20
        }
        It "specials" {
            $UserParams.InputPath = @("$BlaDrive\special ' ! ,; . ordner")
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $test = Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0
            (Get-ChildItem -LiteralPath "$($UserParams.InputPath)\" -Filter $UserParams.Formats[1]).count | Should Be 20
        }
    }
}

Describe "Get-EXIFValues" {
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
            EXIFTransferOnly =      0
            EXIFDeleteAll =         0
            EXIFAddCopyright =      0
            EXIFPresetName =        "default"
            EXIFArtistName =        ""
            EXIFCopyrightText =     ""
            Formats =               @("*.jpeg","*.jpg")
            ConvertQuality =        40
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
            {Get-EXIFValues} | Should Throw
            {Get-EXIFValues -UserParams 123} | Should Throw
            {Get-EXIFValues -UserParams @{}} | Should Throw
        }
        It "Return no errors if all goes well" {
            $test = Get-EXIFValues -UserParams $UserParams
            $test | Should BeOfType hashtable
            $test.EXIFArtistName | Should BeOfType string
            $test.EXIFArtistName | Should Be "Wendy Torrance"
            $test.EXIFCopyrightText | Should BeOfType string
            $test.EXIFCopyrightText | Should Be "Room 237 Enterprises"
        }
        It "Return another preset" {
            $UserParams.EXIFPresetName = "johnnyboy"
            $test = Get-EXIFValues -UserParams $UserParams
            $test | Should BeOfType hashtable
            $test.EXIFArtistName | Should Be "John Daniel Edward Torrance"
            $test.EXIFCopyrightText | Should Be "All-Work-And-No-Play-Makes-Jack-A-Dull-Boy, LLC"
        }
        It "Ask for inputs if no file is found" {
            Mock Test-Path {return $false}
            Mock Read-Host {return "myTest"}
            $test = Get-EXIFValues -UserParams $UserParams
            $test | Should BeOfType hashtable
            $test.EXIFArtistName | Should Be "myTest"
            $test.EXIFCopyrightText | Should Be "myTest"
            Assert-MockCalled -CommandName Read-Host -Times 2
        }
        It "Take param input if some is given" {
            $UserParams.EXIFArtistName = "paramTestName"
            $UserParams.EXIFCopyrightText = "paramTestRight"
            $test = Get-EXIFValues -UserParams $UserParams
            $test | Should BeOfType hashtable
            $test.EXIFArtistName | Should Be "paramTestName"
            $test.EXIFCopyrightText | Should Be "paramTestRight"
        }
    }
    Context "Works with SpecChars" {
        It "From JSON" {
            $UserParams.EXIFPresetName = "testSetSpecChars"
            $test = Get-EXIFValues -UserParams $UserParams
            $test | Should BeOfType hashtable
            $test.EXIFArtistName | Should Be "Æ © J;n 'Daniel' Edward! . `` _"
            $test.EXIFCopyrightText | Should Be "All-Work-And-No-Play-Makes-A-Dull-Boy, [LLC]"
        }
    }
}

Describe "Start-EXIFManipulation" {
    $BlaDrive = "$TestDrive\TEST"
    New-Item -ItemType Directory -Path $BlaDrive
    Push-Location $BlaDrive
    Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x -aoa -bb0 -pdefault -sccUTF-8 -spf2 `"$($PSScriptRoot)\picture_tool_TESTFILES.7z`" `"-o.\`" " -WindowStyle Minimized -Wait
    Pop-Location

    BeforeEach {
        [hashtable]$UserParams = @{
            InputPath =             @("$BlaDrive\123412356789 file.jpg")
            Convert2JPEG =          1
            EXIFManipulation =      1
            EXIFTransferOnly =      0
            EXIFDeleteAll =         0
            EXIFAddCopyright =      0
            EXIFPresetName =        "default"
            EXIFArtistName =        ""
            EXIFCopyrightText =     ""
            Formats =               @("*.jpeg","*.jpg")
            ConvertQuality =        40
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
            {Start-EXIFManipulation} | Should Throw
            {Start-EXIFManipulation -UserParams 123} | Should Throw
            {Start-EXIFManipulation -UserParams @{}} | Should Throw
            {Start-EXIFManipulation -WorkingFiles $WorkingFiles}
            {Start-EXIFManipulation -UserParams $UserParams} | Should Throw
            {Start-EXIFManipulation -UserParams $UserParams -WorkingFiles @()} | Should Throw
        }
        It "Return no errors if all goes well" {
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $UserParams = Get-EXIFValues -UserParams $UserParams
            Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test = Start-EXIFManipulation -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0 # TODO: Æ (U+00C6) is failing!
        }
    }
    Context "Transfer" {
        It "transfer as-is" {
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $UserParams = Get-EXIFValues -UserParams $UserParams
            Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test = Start-EXIFManipulation -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0

            Push-Location $BlaDrive
            $meta = .\exiftool.exe "$($WorkingFiles.JPEGFullName)" -J | ConvertFrom-Json
            Pop-Location
            $meta.Artist                | Should Be "Test Artist"
            $meta.Copyright             | Should Be "Test Copyright"
            $meta.SerialNumber          | Should Be "123456789"
            $meta.Software              | Should Be $null
            $meta.XResolution           | Should Be 300
            $meta.YResolution           | Should Be 300
            $meta.'By-Line'             | Should Be "Test ByLine"
            $meta.CopyrightNotice       | Should Be "Test Copyright"
            $meta.Keywords              | Should Be "Test Keyword"
            $meta.ObjectName            | Should Be "Test ObjectName"
            $meta.Subject               | Should Be "Test Subject"
            $meta.HierarchicalSubject   | Should Be "Test HierarchicalSubject"
            $meta.Label                 | Should Be "Test Label"
            $meta.Rating                | Should Be "4"
            $meta.DocumentID            | Should Be $null

            Remove-Item -LiteralPath $WorkingFiles.JPEGFullName
        }
        It "transfer + add copyright" {
            $UserParams.Convert2JPEG =      1
            $UserParams.EXIFManipulation =  1
            $UserParams.EXIFAddCopyright =  1
            $UserParams.EXIFDeleteAll =     0
            $UserParams.EXIFTransferOnly =  0
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $UserParams = Get-EXIFValues -UserParams $UserParams
            Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            Start-Sleep -Milliseconds 100
            $test = Start-EXIFManipulation -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0

            Push-Location $BlaDrive
            $meta = @(.\exiftool.exe "$($WorkingFiles.JPEGFullName)" -J | ConvertFrom-Json)
            Pop-Location
            $meta.Artist                | Should Be "Wendy Torrance"
            $meta.Copyright             | Should Be "Room 237 Enterprises"
            $meta.SerialNumber          | Should Be "123456789"
            $meta.Software              | Should Be $null
            $meta.XResolution           | Should Be 300
            $meta.YResolution           | Should Be 300
            $meta.'By-Line'             | Should Be "Wendy Torrance"
            $meta.CopyrightNotice       | Should Be "Room 237 Enterprises"
            $meta.Keywords              | Should Be "Test Keyword"
            $meta.ObjectName            | Should Be "Test ObjectName"
            $meta.Subject               | Should Be "Test Subject"
            $meta.HierarchicalSubject   | Should Be "Test HierarchicalSubject"
            $meta.Label                 | Should Be "Test Label"
            $meta.Rating                | Should Be "4"
            $meta.DocumentID            | Should Be $null

            Remove-Item -LiteralPath $WorkingFiles.JPEGFullName
        }
        It "transfer + delete non-cam" {
            $UserParams.Convert2JPEG =      1
            $UserParams.EXIFManipulation =  1
            $UserParams.EXIFAddCopyright =  0
            $UserParams.EXIFDeleteAll =     1
            $UserParams.EXIFTransferOnly =  0
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $UserParams = Get-EXIFValues -UserParams $UserParams
            Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test = Start-EXIFManipulation -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0

            Push-Location $BlaDrive
            $meta = .\exiftool.exe "$($WorkingFiles.JPEGFullName)" -J | ConvertFrom-Json
            Pop-Location
            $meta.Artist                | Should Be "Test Artist"
            $meta.Copyright             | Should Be "Test Copyright"
            $meta.SerialNumber          | Should Be "123456789"
            $meta.Software              | Should Be $null
            $meta.XResolution           | Should Be 300
            $meta.YResolution           | Should Be 300
            $meta.'By-Line'             | Should Be $null
            $meta.CopyrightNotice       | Should Be $null
            $meta.Keywords              | Should Be $null
            $meta.ObjectName            | Should Be $null
            $meta.Subject               | Should Be $null
            $meta.HierarchicalSubject   | Should Be $null
            $meta.Label                 | Should Be $null
            $meta.Rating                | Should Be $null
            $meta.DocumentID            | Should Be $null

            Remove-Item -LiteralPath $WorkingFiles.JPEGFullName
        }
        It "transfer + delete non-cam + add copyright" {
            $UserParams.Convert2JPEG =      1
            $UserParams.EXIFManipulation =  1
            $UserParams.EXIFAddCopyright =  1
            $UserParams.EXIFDeleteAll =     1
            $UserParams.EXIFTransferOnly =  0
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $UserParams = Get-EXIFValues -UserParams $UserParams
            Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test = Start-EXIFManipulation -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0

            Push-Location $BlaDrive
            $meta = .\exiftool.exe "$($WorkingFiles.JPEGFullName)" -J | ConvertFrom-Json
            Pop-Location
            $meta.Artist                | Should Be "Wendy Torrance"
            $meta.Copyright             | Should Be "Room 237 Enterprises"
            $meta.SerialNumber          | Should Be "123456789"
            $meta.Software              | Should Be $null
            $meta.XResolution           | Should Be 300
            $meta.YResolution           | Should Be 300
            $meta.'By-Line'             | Should Be "Wendy Torrance"
            $meta.CopyrightNotice       | Should Be "Room 237 Enterprises"
            $meta.Keywords              | Should Be $null
            $meta.ObjectName            | Should Be $null
            $meta.Subject               | Should Be $null
            $meta.HierarchicalSubject   | Should Be $null
            $meta.Label                 | Should Be $null
            $meta.Rating                | Should Be $null
            $meta.DocumentID            | Should Be $null
            
            Remove-Item -LiteralPath $WorkingFiles.JPEGFullName
        }
        It "delete all" {
            $UserParams.Convert2JPEG =      1
            $UserParams.EXIFManipulation =  1
            $UserParams.EXIFAddCopyright =  0
            $UserParams.EXIFDeleteAll =     2
            $UserParams.EXIFTransferOnly =  0
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $UserParams = Get-EXIFValues -UserParams $UserParams
            Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test = Start-EXIFManipulation -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0

            Push-Location $BlaDrive
            $meta = .\exiftool.exe "$($WorkingFiles.JPEGFullName)" -J | ConvertFrom-Json
            Pop-Location
            $meta.Artist                | Should Be $null
            $meta.Copyright             | Should Be $null
            $meta.SerialNumber          | Should Be $null
            $meta.Software              | Should Be $null
            $meta.XResolution           | Should Be 300
            $meta.YResolution           | Should Be 300
            $meta.'By-Line'             | Should Be $null
            $meta.CopyrightNotice       | Should Be $null
            $meta.Keywords              | Should Be $null
            $meta.ObjectName            | Should Be $null
            $meta.Subject               | Should Be $null
            $meta.HierarchicalSubject   | Should Be $null
            $meta.Label                 | Should Be $null
            $meta.Rating                | Should Be $null
            $meta.DocumentID            | Should Be $null

            Remove-Item -LiteralPath $WorkingFiles.JPEGFullName
        }
        It "delete all + add copyright" {
            $UserParams.Convert2JPEG =      1
            $UserParams.EXIFManipulation =  1
            $UserParams.EXIFAddCopyright =  1
            $UserParams.EXIFDeleteAll =     2
            $UserParams.EXIFTransferOnly =  0
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $UserParams = Get-EXIFValues -UserParams $UserParams
            Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test = Start-EXIFManipulation -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0

            Push-Location $BlaDrive
            $meta = .\exiftool.exe "$($WorkingFiles.JPEGFullName)" -J | ConvertFrom-Json
            Pop-Location
            $meta.Artist                | Should Be "Wendy Torrance"
            $meta.Copyright             | Should Be "Room 237 Enterprises"
            $meta.SerialNumber          | Should Be $null
            $meta.Software              | Should Be $null
            $meta.XResolution           | Should Be 300
            $meta.YResolution           | Should Be 300
            $meta.'By-Line'             | Should Be "Wendy Torrance"
            $meta.CopyrightNotice       | Should Be "Room 237 Enterprises"
            $meta.Keywords              | Should Be $null
            $meta.ObjectName            | Should Be $null
            $meta.Subject               | Should Be $null
            $meta.HierarchicalSubject   | Should Be $null
            $meta.Label                 | Should Be $null
            $meta.Rating                | Should Be $null
            $meta.DocumentID            | Should Be $null

            Remove-Item -LiteralPath $WorkingFiles.JPEGFullName
        }
    }
    Context "Modify" {
        It "modify (keep as is)" {
            Copy-Item -Path $UserParams.InputPath[0] -Destination $BlaDrive\bla.jpg
            $UserParams.InputPath = @("$BlaDrive\bla.jpg")
            $UserParams.Convert2JPEG =      0
            $UserParams.EXIFManipulation =  1
            $UserParams.EXIFAddCopyright =  0
            $UserParams.EXIFDeleteAll =     0
            $UserParams.EXIFTransferOnly =  0
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $UserParams = Get-EXIFValues -UserParams $UserParams
            $test = Start-EXIFManipulation -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0

            Push-Location $BlaDrive
            $meta = .\exiftool.exe "$($WorkingFiles.SourceFullName)" -J | ConvertFrom-Json
            Pop-Location
            $meta.Artist                | Should Be "Test Artist"
            $meta.Copyright             | Should Be "Test Copyright"
            $meta.SerialNumber          | Should Be "123456789"
            $meta.Software              | Should Be $null
            $meta.XResolution           | Should Be 300
            $meta.YResolution           | Should Be 300
            $meta.'By-Line'             | Should Be "Test ByLine"
            $meta.CopyrightNotice       | Should Be "Test Copyright"
            $meta.Keywords              | Should Be "Test Keyword"
            $meta.ObjectName            | Should Be "Test ObjectName"
            $meta.Subject               | Should Be "Test Subject"
            $meta.HierarchicalSubject   | Should Be "Test HierarchicalSubject"
            $meta.Label                 | Should Be "Test Label"
            $meta.Rating                | Should Be "4"
            $meta.DocumentID            | Should Be $null

            Remove-Item -LiteralPath $WorkingFiles.SourceFullName
        }
        It "modify (add copyright)" {
            Copy-Item -Path $UserParams.InputPath[0] -Destination $BlaDrive\bla.jpg -Force
            $UserParams.InputPath = @("$BlaDrive\bla.jpg")
            $UserParams.Convert2JPEG =      0
            $UserParams.EXIFManipulation =  1
            $UserParams.EXIFAddCopyright =  1
            $UserParams.EXIFDeleteAll =     0
            $UserParams.EXIFTransferOnly =  0
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $UserParams = Get-EXIFValues -UserParams $UserParams
            $test = Start-EXIFManipulation -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0

            Push-Location $BlaDrive
            $meta = .\exiftool.exe "$($WorkingFiles.SourceFullName)" -J | ConvertFrom-Json
            Pop-Location
            $meta.Artist                | Should Be "Wendy Torrance"
            $meta.Copyright             | Should Be "Room 237 Enterprises"
            $meta.SerialNumber          | Should Be "123456789"
            $meta.Software              | Should Be $null
            $meta.XResolution           | Should Be 300
            $meta.YResolution           | Should Be 300
            $meta.'By-Line'             | Should Be "Wendy Torrance"
            $meta.CopyrightNotice       | Should Be "Room 237 Enterprises"
            $meta.Keywords              | Should Be "Test Keyword"
            $meta.ObjectName            | Should Be "Test ObjectName"
            $meta.Subject               | Should Be "Test Subject"
            $meta.HierarchicalSubject   | Should Be "Test HierarchicalSubject"
            $meta.Label                 | Should Be "Test Label"
            $meta.Rating                | Should Be "4"
            $meta.DocumentID            | Should Be $null

            Remove-Item -LiteralPath $WorkingFiles.SourceFullName
        }
        It "modify (delete non-cam)" {
            Copy-Item -Path $UserParams.InputPath[0] -Destination $BlaDrive\bla.jpg
            $UserParams.InputPath = @("$BlaDrive\bla.jpg")
            $UserParams.Convert2JPEG =      0
            $UserParams.EXIFManipulation =  1
            $UserParams.EXIFAddCopyright =  0
            $UserParams.EXIFDeleteAll =     1
            $UserParams.EXIFTransferOnly =  0
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $UserParams = Get-EXIFValues -UserParams $UserParams
            $test = Start-EXIFManipulation -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0

            Push-Location $BlaDrive
            $meta = .\exiftool.exe "$($WorkingFiles.SourceFullName)" -J | ConvertFrom-Json
            Pop-Location
            $meta.Artist                | Should Be "Test Artist"
            $meta.Copyright             | Should Be "Test Copyright"
            $meta.SerialNumber          | Should Be "123456789"
            $meta.Software              | Should Be $null
            $meta.XResolution           | Should Be 300
            $meta.YResolution           | Should Be 300
            $meta.'By-Line'             | Should Be $null
            $meta.CopyrightNotice       | Should Be $null
            $meta.Keywords              | Should Be $null
            $meta.ObjectName            | Should Be $null
            $meta.Subject               | Should Be $null
            $meta.HierarchicalSubject   | Should Be $null
            $meta.Label                 | Should Be $null
            $meta.Rating                | Should Be $null
            $meta.DocumentID            | Should Be $null

            Remove-Item -LiteralPath $WorkingFiles.SourceFullName
        }
        It "modify (delete non-cam + add copyright)" {
            Copy-Item -Path $UserParams.InputPath[0] -Destination $BlaDrive\bla.jpg -Force
            $UserParams.InputPath = @("$BlaDrive\bla.jpg")
            $UserParams.Convert2JPEG =      0
            $UserParams.EXIFManipulation =  1
            $UserParams.EXIFAddCopyright =  1
            $UserParams.EXIFDeleteAll =     1
            $UserParams.EXIFTransferOnly =  0
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $UserParams = Get-EXIFValues -UserParams $UserParams
            $test = Start-EXIFManipulation -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0

            Push-Location $BlaDrive
            $meta = .\exiftool.exe "$($WorkingFiles.SourceFullName)" -J | ConvertFrom-Json
            Pop-Location
            $meta.Artist                | Should Be "Wendy Torrance"
            $meta.Copyright             | Should Be "Room 237 Enterprises"
            $meta.SerialNumber          | Should Be "123456789"
            $meta.Software              | Should Be $null
            $meta.XResolution           | Should Be 300
            $meta.YResolution           | Should Be 300
            $meta.'By-Line'             | Should Be "Wendy Torrance"
            $meta.CopyrightNotice       | Should Be "Room 237 Enterprises"
            $meta.Keywords              | Should Be $null
            $meta.ObjectName            | Should Be $null
            $meta.Subject               | Should Be $null
            $meta.HierarchicalSubject   | Should Be $null
            $meta.Label                 | Should Be $null
            $meta.Rating                | Should Be $null
            $meta.DocumentID            | Should Be $null

            Remove-Item -LiteralPath $WorkingFiles.SourceFullName
        }
        It "modify (delete all)" {
            Copy-Item -Path $UserParams.InputPath[0] -Destination $BlaDrive\bla.jpg
            $UserParams.InputPath = @("$BlaDrive\bla.jpg")
            $UserParams.Convert2JPEG =      0
            $UserParams.EXIFManipulation =  1
            $UserParams.EXIFAddCopyright =  0
            $UserParams.EXIFDeleteAll =     2
            $UserParams.EXIFTransferOnly =  0
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $UserParams = Get-EXIFValues -UserParams $UserParams
            $test = Start-EXIFManipulation -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0

            Push-Location $BlaDrive
            $meta = .\exiftool.exe "$($WorkingFiles.SourceFullName)" -J | ConvertFrom-Json
            Pop-Location
            $meta.Artist                | Should Be $null
            $meta.Copyright             | Should Be $null
            $meta.SerialNumber          | Should Be $null
            $meta.Software              | Should Be $null
            $meta.XResolution           | Should Be 300
            $meta.YResolution           | Should Be 300
            $meta.'By-Line'             | Should Be $null
            $meta.CopyrightNotice       | Should Be $null
            $meta.Keywords              | Should Be $null
            $meta.ObjectName            | Should Be $null
            $meta.Subject               | Should Be $null
            $meta.HierarchicalSubject   | Should Be $null
            $meta.Label                 | Should Be $null
            $meta.Rating                | Should Be $null
            $meta.DocumentID            | Should Be $null

            Remove-Item -LiteralPath $WorkingFiles.SourceFullName
        }
        It "modify (delete all + add copyright)" {
            Copy-Item -Path $UserParams.InputPath[0] -Destination $BlaDrive\bla.jpg
            $UserParams.InputPath = @("$BlaDrive\bla.jpg")
            $UserParams.Convert2JPEG =      0
            $UserParams.EXIFManipulation =  1
            $UserParams.EXIFAddCopyright =  1
            $UserParams.EXIFDeleteAll =     2
            $UserParams.EXIFTransferOnly =  0
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $UserParams = Get-EXIFValues -UserParams $UserParams
            $test = Start-EXIFManipulation -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0

            Push-Location $BlaDrive
            $meta = .\exiftool.exe "$($WorkingFiles.SourceFullName)" -J | ConvertFrom-Json
            Pop-Location
            $meta.Artist                | Should Be "Wendy Torrance"
            $meta.Copyright             | Should Be "Room 237 Enterprises"
            $meta.SerialNumber          | Should Be $null
            $meta.Software              | Should Be $null
            $meta.XResolution           | Should Be 300
            $meta.YResolution           | Should Be 300
            $meta.'By-Line'             | Should Be "Wendy Torrance"
            $meta.CopyrightNotice       | Should Be "Room 237 Enterprises"
            $meta.Keywords              | Should Be $null
            $meta.ObjectName            | Should Be $null
            $meta.Subject               | Should Be $null
            $meta.HierarchicalSubject   | Should Be $null
            $meta.Label                 | Should Be $null
            $meta.Rating                | Should Be $null
            $meta.DocumentID            | Should Be $null

            Remove-Item -LiteralPath $WorkingFiles.SourceFullName
        }
    }
    Context "No problems with SpecChars" {
        It "12345" {
            # $script:Debug = 1
            $UserParams.InputPath = @("$BlaDrive\123456789 ordner\Æfile.jpg","$BlaDrive\123456789 ordner\Æfile_1.jpg")
            $UserParams.InputPath = @("$BlaDrive\123456789 ordner")
            # TODO: Interestingly, either file works on its own, but not both together...
            $UserParams.Convert2JPEG =      1
            $UserParams.EXIFManipulation =  1
            $UserParams.EXIFAddCopyright =  1
            $UserParams.EXIFDeleteAll =     0
            $UserParams.EXIFTransferOnly =  0
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $UserParams = Get-EXIFValues -UserParams $UserParams
            Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            Start-Sleep -Milliseconds 100
            $test = Start-EXIFManipulation -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0 # TODO: Æ (U+00C6) is failing!

            Push-Location $BlaDrive
            foreach($i in $WorkingFiles.JPEGFullName){
                $meta = @()
                $meta = @(.\exiftool.exe "$i" -J | ConvertFrom-Json)
                $meta.Artist                | Should Be "Wendy Torrance"
                $meta.Copyright             | Should Be "Room 237 Enterprises"
                $meta.SerialNumber          | Should Be "123456789"
                $meta.Software              | Should Be $null
                $meta.XResolution           | Should Be 300
                $meta.YResolution           | Should Be 300
                $meta.'By-Line'             | Should Be "Wendy Torrance"
                $meta.CopyrightNotice       | Should Be "Room 237 Enterprises"
                $meta.Keywords              | Should Be "Test Keyword"
                $meta.ObjectName            | Should Be "Test ObjectName"
                $meta.Subject               | Should Be "Test Subject"
                $meta.HierarchicalSubject   | Should Be "Test HierarchicalSubject"
                $meta.Label                 | Should Be "Test Label"
                $meta.Rating                | Should Be "4"
                $meta.DocumentID            | Should Be $null
                }
            Pop-Location
        }
        It "Æ" {
            $UserParams.InputPath = @("$BlaDrive\ÆOrdner")
            $UserParams.Convert2JPEG =      1
            $UserParams.EXIFManipulation =  1
            $UserParams.EXIFAddCopyright =  1
            $UserParams.EXIFDeleteAll =     0
            $UserParams.EXIFTransferOnly =  0
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $UserParams = Get-EXIFValues -UserParams $UserParams
            Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            Start-Sleep -Milliseconds 100
            $test = Start-EXIFManipulation -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0

            Push-Location $BlaDrive
            foreach($i in $WorkingFiles.JPEGFullName){
                $meta = @()
                $meta = @(.\exiftool.exe "$i" -J | ConvertFrom-Json)
                $meta.Artist                | Should Be "Wendy Torrance"
                $meta.Copyright             | Should Be "Room 237 Enterprises"
                $meta.SerialNumber          | Should Be "123456789"
                $meta.Software              | Should Be $null
                $meta.XResolution           | Should Be 300
                $meta.YResolution           | Should Be 300
                $meta.'By-Line'             | Should Be "Wendy Torrance"
                $meta.CopyrightNotice       | Should Be "Room 237 Enterprises"
                $meta.Keywords              | Should Be "Test Keyword"
                $meta.ObjectName            | Should Be "Test ObjectName"
                $meta.Subject               | Should Be "Test Subject"
                $meta.HierarchicalSubject   | Should Be "Test HierarchicalSubject"
                $meta.Label                 | Should Be "Test Label"
                $meta.Rating                | Should Be "4"
                $meta.DocumentID            | Should Be $null
            }
            Pop-Location
        }
        It "©" {
            $UserParams.InputPath = @("$BlaDrive\©Ordner")
            $UserParams.Convert2JPEG =      1
            $UserParams.EXIFManipulation =  1
            $UserParams.EXIFAddCopyright =  1
            $UserParams.EXIFPresetName =    "testSetSpecChars"
            $UserParams.EXIFDeleteAll =     0
            $UserParams.EXIFTransferOnly =  0
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $UserParams = Get-EXIFValues -UserParams $UserParams
            Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            Start-Sleep -Milliseconds 100
            $test = Start-EXIFManipulation -UserParams $UserParams -WorkingFiles $WorkingFiles

            Push-Location $BlaDrive
            foreach($i in $WorkingFiles.JPEGFullName){
                $meta = @()
                $meta = @(.\exiftool.exe "$i" -J | ConvertFrom-Json)
                $meta.Artist                | Should Be "Æ © J;n 'Daniel' Edward! . `` _"
                $meta.Copyright             | Should Be "All-Work-And-No-Play-Makes-A-Dull-Boy, [LLC]"
                $meta.SerialNumber          | Should Be "123456789"
                $meta.Software              | Should Be $null
                $meta.XResolution           | Should Be 300
                $meta.YResolution           | Should Be 300
                $meta.'By-Line'             | Should Be "Æ © J;n 'Daniel' Edward! . `` _"
                $meta.CopyrightNotice       | Should Be "All-Work-And-No-Play-Makes-A-Dull-Boy, [LLC]"
                $meta.Keywords              | Should Be "Test Keyword"
                $meta.ObjectName            | Should Be "Test ObjectName"
                $meta.Subject               | Should Be "Test Subject"
                $meta.HierarchicalSubject   | Should Be "Test HierarchicalSubject"
                $meta.Label                 | Should Be "Test Label"
                $meta.Rating                | Should Be "4"
                $meta.DocumentID            | Should Be $null
            }
            Pop-Location
        }
        It "backtick" {
            $UserParams.InputPath = @("$BlaDrive\backtick ````ordner ``")
            $UserParams.Convert2JPEG =      1
            $UserParams.EXIFManipulation =  1
            $UserParams.EXIFAddCopyright =  1
            $UserParams.EXIFArtistName = "Æsildur"
            $UserParams.EXIFDeleteAll =     0
            $UserParams.EXIFTransferOnly =  0
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $UserParams = Get-EXIFValues -UserParams $UserParams
            Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            Start-Sleep -Milliseconds 100
            $test = Start-EXIFManipulation -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0

            Push-Location $BlaDrive
            foreach($i in $WorkingFiles.JPEGFullName){
                $meta = @()
                $meta = @(.\exiftool.exe "$i" -J | ConvertFrom-Json)
                $meta.Artist                | Should Be "Æsildur"
                $meta.Copyright             | Should Be "Room 237 Enterprises"
                $meta.SerialNumber          | Should Be "123456789"
                $meta.Software              | Should Be $null
                $meta.XResolution           | Should Be 300
                $meta.YResolution           | Should Be 300
                $meta.'By-Line'             | Should Be "Æsildur"
                $meta.CopyrightNotice       | Should Be "Room 237 Enterprises"
                $meta.Keywords              | Should Be "Test Keyword"
                $meta.ObjectName            | Should Be "Test ObjectName"
                $meta.Subject               | Should Be "Test Subject"
                $meta.HierarchicalSubject   | Should Be "Test HierarchicalSubject"
                $meta.Label                 | Should Be "Test Label"
                $meta.Rating                | Should Be "4"
                $meta.DocumentID            | Should Be $nulll
            }
            Pop-Location
        }
        It "bracket" {
            $UserParams.InputPath = @("$BlaDrive\bracket [ ] ordner")
            $UserParams.Convert2JPEG =      1
            $UserParams.EXIFManipulation =  1
            $UserParams.EXIFAddCopyright =  1
            $UserParams.EXIFDeleteAll =     0
            $UserParams.EXIFTransferOnly =  0
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $UserParams = Get-EXIFValues -UserParams $UserParams
            Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            Start-Sleep -Milliseconds 100
            $test = Start-EXIFManipulation -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0 # TODO: Æ (U+00C6) is failing!

            Push-Location $BlaDrive
            foreach($i in $WorkingFiles.JPEGFullName){
                $meta = @()
                $meta = @(.\exiftool.exe "$i" -J | ConvertFrom-Json)
                $meta.Artist                | Should Be "Wendy Torrance"
                $meta.Copyright             | Should Be "Room 237 Enterprises"
                $meta.SerialNumber          | Should Be "123456789"
                $meta.Software              | Should Be $null
                $meta.XResolution           | Should Be 300
                $meta.YResolution           | Should Be 300
                $meta.'By-Line'             | Should Be "Wendy Torrance"
                $meta.CopyrightNotice       | Should Be "Room 237 Enterprises"
                $meta.Keywords              | Should Be "Test Keyword"
                $meta.ObjectName            | Should Be "Test ObjectName"
                $meta.Subject               | Should Be "Test Subject"
                $meta.HierarchicalSubject   | Should Be "Test HierarchicalSubject"
                $meta.Label                 | Should Be "Test Label"
                $meta.Rating                | Should Be "4"
                $meta.DocumentID            | Should Be $null
            }
            Pop-Location
        }
        It "dots" {
            $UserParams.InputPath = @("$BlaDrive\ordner.mit.punkten")
            $UserParams.Convert2JPEG =      1
            $UserParams.EXIFManipulation =  1
            $UserParams.EXIFAddCopyright =  1
            $UserParams.EXIFDeleteAll =     0
            $UserParams.EXIFTransferOnly =  0
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $UserParams = Get-EXIFValues -UserParams $UserParams
            Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            Start-Sleep -Milliseconds 100
            $test = Start-EXIFManipulation -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0 # TODO: Æ (U+00C6) is failing!

            Push-Location $BlaDrive
            foreach($i in $WorkingFiles.JPEGFullName){
                $meta = @()
                $meta = @(.\exiftool.exe "$i" -J | ConvertFrom-Json)
                $meta.Artist                | Should Be "Wendy Torrance"
                $meta.Copyright             | Should Be "Room 237 Enterprises"
                $meta.SerialNumber          | Should Be "123456789"
                $meta.Software              | Should Be $null
                $meta.XResolution           | Should Be 300
                $meta.YResolution           | Should Be 300
                $meta.'By-Line'             | Should Be "Wendy Torrance"
                $meta.CopyrightNotice       | Should Be "Room 237 Enterprises"
                $meta.Keywords              | Should Be "Test Keyword"
                $meta.ObjectName            | Should Be "Test ObjectName"
                $meta.Subject               | Should Be "Test Subject"
                $meta.HierarchicalSubject   | Should Be "Test HierarchicalSubject"
                $meta.Label                 | Should Be "Test Label"
                $meta.Rating                | Should Be "4"
                $meta.DocumentID            | Should Be $null
            }
            Pop-Location
        }
        It "specials" {
            $UserParams.InputPath = @("$BlaDrive\special ' ! ,; . ordner")
            $UserParams.Convert2JPEG =      1
            $UserParams.EXIFManipulation =  1
            $UserParams.EXIFAddCopyright =  1
            $UserParams.EXIFDeleteAll =     0
            $UserParams.EXIFTransferOnly =  0
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $UserParams = Get-EXIFValues -UserParams $UserParams
            Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            Start-Sleep -Milliseconds 100
            $test = Start-EXIFManipulation -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0 # TODO: Æ (U+00C6) is failing!

            Push-Location $BlaDrive
            foreach($i in $WorkingFiles.JPEGFullName){
                $meta = @()
                $meta = @(.\exiftool.exe "$i" -J | ConvertFrom-Json)
                $meta.Artist                | Should Be "Wendy Torrance"
                $meta.Copyright             | Should Be "Room 237 Enterprises"
                $meta.SerialNumber          | Should Be "123456789"
                $meta.Software              | Should Be $null
                $meta.XResolution           | Should Be 300
                $meta.YResolution           | Should Be 300
                $meta.'By-Line'             | Should Be "Wendy Torrance"
                $meta.CopyrightNotice       | Should Be "Room 237 Enterprises"
                $meta.Keywords              | Should Be "Test Keyword"
                $meta.ObjectName            | Should Be "Test ObjectName"
                $meta.Subject               | Should Be "Test Subject"
                $meta.HierarchicalSubject   | Should Be "Test HierarchicalSubject"
                $meta.Label                 | Should Be "Test Label"
                $meta.Rating                | Should Be "4"
                $meta.DocumentID            | Should Be $null
            }
            Pop-Location
        }
    }
}

Describe "Start-Recycling" {
    $BlaDrive = "$TestDrive\TEST"
    New-Item -ItemType Directory -Path $BlaDrive
    Push-Location $BlaDrive
    Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x -aoa -bb0 -pdefault -sccUTF-8 -spf2 `"$($PSScriptRoot)\picture_tool_TESTFILES.7z`" `"-o.\`" " -WindowStyle Minimized -Wait
    Pop-Location

    BeforeEach {
        [hashtable]$UserParams = @{
            InputPath =             @("$BlaDrive")
            Convert2JPEG =          1
            Formats =               @("*.jpeg","*.jpg")
            ConvertQuality =        40
            ConvertRemoveSource =   1
            Convert2SRGB =          0
            ConvertScaling =        50
            Magick =                "$BlaDrive\ImageMagick\magick.exe"
            MagickThreads =         12
        }
    }

    Context "Basics" {
        It "Throw if no/wrong param" {
            {Start-Recycling} | Should Throw
            {Start-Recycling -WorkingFiles @()} | Should Throw
        }
        It "Return no errors if all goes well" {
            # TODO: Recycle.psm1 needs to have -LiteralPath at Get-Item to get working!
            # $script:Debug = 1
            $WorkingFiles = @(Get-InputFiles -UserParams $UserParams)
            Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test = Start-Recycling -WorkingFiles $WorkingFiles
            $test | Should Be 0
            $bla = (Get-ChildItem $UserParams.InputPath[0] -Filter *.jpg -File).Fullname
            $bla.Length | Should Be $WorkingFiles.Length
        }
    }
    Context "No problems with SpecChars" {
        It "12345" {
            $UserParams.InputPath = @("$BlaDrive\123456789 ordner")
            $WorkingFiles = @(Get-InputFiles -UserParams $UserParams)
            Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test = Start-Recycling -WorkingFiles $WorkingFiles
            $test | Should Be 0
            $bla = (Get-ChildItem $UserParams.InputPath[0] -Filter *.jpg -File).Fullname
            $bla.Length | Should Be $WorkingFiles.Length
        }
        It "Æ" {
            $UserParams.InputPath = @("$BlaDrive\ÆOrdner")
            $WorkingFiles = @(Get-InputFiles -UserParams $UserParams)
            Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test = Start-Recycling -WorkingFiles $WorkingFiles
            $test | Should Be 0
            $bla = (Get-ChildItem $UserParams.InputPath[0] -Filter *.jpg -File).Fullname
            $bla.Length | Should Be $WorkingFiles.Length
        }
        It "©" {
            $UserParams.InputPath = @("$BlaDrive\©Ordner")
            $WorkingFiles = @(Get-InputFiles -UserParams $UserParams)
            Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test = Start-Recycling -WorkingFiles $WorkingFiles
            $test | Should Be 0
            $bla = (Get-ChildItem $UserParams.InputPath[0] -Filter *.jpg -File).Fullname
            $bla.Length | Should Be $WorkingFiles.Length
        }
        It "backtick" {
            $UserParams.InputPath = @("$BlaDrive\backtick ````ordner ``")
            $WorkingFiles = @(Get-InputFiles -UserParams $UserParams)
            Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test = Start-Recycling -WorkingFiles $WorkingFiles
            $test | Should Be 0
            $bla = (Get-ChildItem $UserParams.InputPath[0] -Filter *.jpg -File).Fullname
            $bla.Length | Should Be $WorkingFiles.Length
        }
        It "bracket" {
            $UserParams.InputPath = @("$BlaDrive\bracket [ ] ordner")
            $WorkingFiles = @(Get-InputFiles -UserParams $UserParams)
            Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test = Start-Recycling -WorkingFiles $WorkingFiles
            $test | Should Be 0
            $bla = (Get-ChildItem -LiteralPath $UserParams.InputPath[0] -Filter *.jpg -File).Fullname
            $bla.Length | Should Be $WorkingFiles.Length
        }
        It "dots" {
            $UserParams.InputPath = @("$BlaDrive\ordner.mit.punkten")
            $WorkingFiles = @(Get-InputFiles -UserParams $UserParams)
            Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test = Start-Recycling -WorkingFiles $WorkingFiles
            $test | Should Be 0
            $bla = (Get-ChildItem $UserParams.InputPath[0] -Filter *.jpg -File).Fullname
            $bla.Length | Should Be $WorkingFiles.Length
        }
        It "specials" {
            $UserParams.InputPath = @("$BlaDrive\special ' ! ,; . ordner")
            $WorkingFiles = @(Get-InputFiles -UserParams $UserParams)
            Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test = Start-Recycling -WorkingFiles $WorkingFiles
            $test | Should Be 0
            $bla = (Get-ChildItem $UserParams.InputPath[0] -Filter *.jpg -File).Fullname
            $bla.Length | Should Be $WorkingFiles.Length
        }
    }
}

<# TODO: Mock everything to see if params call everything correctly.
    Describe "Start-Everything" {

    }
#>