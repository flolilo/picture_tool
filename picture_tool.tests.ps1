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
            Magick =                "$BlaDrive\magick.exe"
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
            $UserParams.Magick =                "$BlaDrive\magick.exe"
            $test = Test-EXEPaths -UserParams $UserParams
            $test | Should BeOfType hashtable
            $test.ConvertQuality | Should Be 92

            $UserParams.Convert2JPEG =          0
            $UserParams.EXIFManipulation =      1
            $UserParams.EXIFtool=               "$BlaDrive\exiftool.exe"
            $UserParams.Magick =                "$BlaDrive\nomagick.exe"
            $test = Test-EXEPaths -UserParams $UserParams
            $test | Should BeOfType hashtable
            $test.ConvertQuality | Should Be 92
        }
    }
    It "No problems with SpecChars" {
        $UserParams.EXIFtoolFailSafe =  0
        $UserParams.Convert2JPEG =      1
        $UserParams.EXIFManipulation =  1
        $UserParams.EXIFtool = "$BlaDrive\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©\exiftool specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©.exe"
        $UserParams.Magick = "$BlaDrive\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©\magick specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©.exe"
        $test = Test-EXEPaths -UserParams $UserParams
        $test | Should BeOfType hashtable
        $test.ConvertQuality | Should Be 92
    }
    It "No problems with long paths" {
        $UserParams.EXIFtoolFailSafe =  0
        $UserParams.Convert2JPEG =      1
        $UserParams.EXIFManipulation =  1
        $UserParams.EXIFtool = "$BlaDrive\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND\exiftool_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforEND.exe"
        $UserParams.Magick = "$BlaDrive\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND\magick_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_before_END.exe"
        $test = Test-EXEPaths -UserParams $UserParams
        $test | Should BeOfType hashtable
        $test.ConvertQuality | Should Be 92
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
            Magick =                "$BlaDrive\magick.exe"
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
            $test.Length | Should Be 3
        }
        It "Return array even with one item" {
            $UserParams.Formats = @("*.png")
            $test = @(Get-InputFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.SourceName | Should Be "single_PNG.png"
        }
        It "Trailing backslash does not concern the program" {
            $UserParams.InputPath = @("$BlaDrive\")
            $test = @(Get-InputFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 3
        }
        It "Get multiple folders" {
            $UserParams.InputPath = @("$BlaDrive","$BlaDrive\folder_uncomplicated")
            $test = @(Get-InputFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 7
        }
        It "Get single file" {
            $UserParams.InputPath = @("$BlaDrive\file_uncomplicated.jpg")
            $test = @(Get-InputFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 1
        }
        It "Get multiple files" {
            $UserParams.InputPath = @("$BlaDrive\file_uncomplicated.jpg","$BlaDrive\folder_uncomplicated\file_uncomplicated.jpg")
            $test = @(Get-InputFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 2
        }
        It "Get mixed content" {
            $UserParams.InputPath = @("$BlaDrive","$BlaDrive\file_uncomplicated.jpg")
            $test = @(Get-InputFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 4
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
    It "Get -Format files as result files, get all others as source files (-EXIFTransferOnly)" {
        $UserParams.Convert2JPEG = 0
        $UserParams.EXIFTransferOnly = 1
        $UserParams.InputPath = @("$BlaDrive\folder_uncomplicated")

        $test = @(Get-InputFiles -UserParams $UserParams)
        $test.SourceFullName | Should -Not -Match '.file_notintransfer\.webp$'
        $test.SourceFullName | Should -Not -Match '.file_notintransfer\.tif$'
        $test.SourceFullName | Should -Match '.file_intransfer\.tif$'
        $test.SourceFullName | Should -Not -Match '.file_intransfer\.jpg$'
    }
    It "No problems with SpecChars" {
        $UserParams.InputPath = @("$BlaDrive\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©")
        $test = @(Get-InputFiles -UserParams $UserParams)
        ,$test | Should BeOfType array
        $test.Length | Should Be 3
    }
    It "No problems with long folder" {
        $UserParams.InputPath = @("$BlaDrive\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND")
        $test = @(Get-InputFiles -UserParams $UserParams)
        ,$test | Should BeOfType array
        $test.Length | Should Be 3
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
            Magick =                "$BlaDrive\magick.exe"
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
            $test | Should BeOfType int
            $test | Should Be 0
            (Get-ChildItem -LiteralPath "$($UserParams.InputPath)\" -Filter $UserParams.Formats[1]).count | Should Be 6
            $bla = (Get-ChildItem -LiteralPath $UserParams.InputPath -Filter $UserParams.Formats[1]).FullName
            $bla | ForEach-Object {
                if($WorkingFiles.SourceFullName -notcontains $_){
                    Remove-Item -LiteralPath $_ -Verbose
                }else{
                    Write-Host "Stay $($_)"
                }
            }
        }
        It "Work with all settings" {
            $UserParams.Convert2SRGB =      1
            $UserParams.ConvertQuality =    10
            $UserParams.ConvertScaling =    10
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $test = Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0

            Push-Location $BlaDrive
            $WorkingFiles | ForEach-Object {
                if($_.ResultShortName -ne "ZYX"){
                    $_.ResultFullName = $_.ResultShortName
                }
            }
            foreach($i in $WorkingFiles.ResultFullName){
                $meta = @()
                $meta = @(.\exiftool.exe "$i" -All:All -J | ConvertFrom-Json)
                $meta.EncodingProcess   | Should Be "Progressive DCT, Huffman coding"
                # TODO: does not yet show up with test-files...
                # $meta.YCbCrSubSampling  | Should Be "YCbCr4:4:4 (1 1)"
                $meta.BitsPerSample     | Should Be "8"
            }
            Pop-Location
            (Get-ChildItem -LiteralPath "$($UserParams.InputPath)\" -Filter $UserParams.Formats[1]).count | Should Be 6
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
            $test | Should Be 3
            Assert-MockCalled Start-Process -Times 3
        }
    }
    It "No problems with SpecChars" {
        $UserParams.InputPath = @("$BlaDrive\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©")
        $WorkingFiles = Get-InputFiles -UserParams $UserParams
        $test = Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
        $test | Should Be 0
        (Get-ChildItem -LiteralPath "$($UserParams.InputPath)\" -Filter $UserParams.Formats[1]).count | Should Be 6
    }
    It "No problems with long paths" {
        $UserParams.InputPath = @("$BlaDrive\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND")
        $WorkingFiles = Get-InputFiles -UserParams $UserParams
        $test = Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
        $test | Should Be 0
        (Get-ChildItem -LiteralPath "$($UserParams.InputPath)\" -Filter $UserParams.Formats[1]).count | Should Be 6
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
            Magick =                "$BlaDrive\magick.exe"
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
            InputPath =             @("$BlaDrive\file_uncomplicated.jpg")
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
            Magick =                "$BlaDrive\magick.exe"
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
            $test | Should Be 0
        }
        It "Works with hundreds of files" {
            # $script:Debug = 1
            $UserParams.InputPath = @("$BlaDrive\hundreds_of_files")
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

            $WorkingFiles | ForEach-Object {
                if($_.ResultShortName -ne "ZYX"){
                    $_.ResultFullName = $_.ResultShortName
                }
            }
            Push-Location $BlaDrive
            Write-Host "Testing values..." -ForegroundColor DarkCyan
            # set for-loop to check each 20th file, as calling exiftool once per file takes forever.
            for($i=0; $i -le $($WorkingFiles.ResultFullName.Length - 20); $i+=20){
                $meta = @()
                $meta = @(.\exiftool.exe "$($WorkingFiles.ResultFullName[$i])" -J | ConvertFrom-Json)
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
    Context "Transfer" {
        It "transfer as-is" {
            $WorkingFiles = Get-InputFiles -UserParams $UserParams
            $UserParams = Get-EXIFValues -UserParams $UserParams
            Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test = Start-EXIFManipulation -UserParams $UserParams -WorkingFiles $WorkingFiles
            $test | Should Be 0

            $WorkingFiles | ForEach-Object {
                if($_.ResultShortName -ne "ZYX"){
                    $_.ResultFullName = $_.ResultShortName
                }
            }
            Push-Location $BlaDrive
            $meta = .\exiftool.exe "$($WorkingFiles.ResultFullName)" -J | ConvertFrom-Json
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

            Remove-Item -LiteralPath $WorkingFiles.ResultFullName
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

            $WorkingFiles | ForEach-Object {
                if($_.ResultShortName -ne "ZYX"){
                    $_.ResultFullName = $_.ResultShortName
                }
            }
            Push-Location $BlaDrive
            $meta = @(.\exiftool.exe "$($WorkingFiles.ResultFullName)" -J | ConvertFrom-Json)
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

            Remove-Item -LiteralPath $WorkingFiles.ResultFullName
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

            $WorkingFiles | ForEach-Object {
                if($_.ResultShortName -ne "ZYX"){
                    $_.ResultFullName = $_.ResultShortName
                }
            }
            Push-Location $BlaDrive
            $meta = .\exiftool.exe "$($WorkingFiles.ResultFullName)" -J | ConvertFrom-Json
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

            Remove-Item -LiteralPath $WorkingFiles.ResultFullName
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

            $WorkingFiles | ForEach-Object {
                if($_.ResultShortName -ne "ZYX"){
                    $_.ResultFullName = $_.ResultShortName
                }
            }
            Push-Location $BlaDrive
            $meta = .\exiftool.exe "$($WorkingFiles.ResultFullName)" -J | ConvertFrom-Json
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
            
            Remove-Item -LiteralPath $WorkingFiles.ResultFullName
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

            $WorkingFiles | ForEach-Object {
                if($_.ResultShortName -ne "ZYX"){
                    $_.ResultFullName = $_.ResultShortName
                }
            }
            Push-Location $BlaDrive
            $meta = .\exiftool.exe "$($WorkingFiles.ResultFullName)" -J | ConvertFrom-Json
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

            Remove-Item -LiteralPath $WorkingFiles.ResultFullName
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

            $WorkingFiles | ForEach-Object {
                if($_.ResultShortName -ne "ZYX"){
                    $_.ResultFullName = $_.ResultShortName
                }
            }
            Push-Location $BlaDrive
            $meta = .\exiftool.exe "$($WorkingFiles.ResultFullName)" -J | ConvertFrom-Json
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

            Remove-Item -LiteralPath $WorkingFiles.ResultFullName
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

            $WorkingFiles | ForEach-Object {
                if($_.ResultShortName -ne "ZYX"){
                    $_.ResultFullName = $_.ResultShortName
                }
            }
            Push-Location $BlaDrive
            $meta = .\exiftool.exe "$($WorkingFiles.ResultFullName)" -J | ConvertFrom-Json
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

            Remove-Item -LiteralPath $WorkingFiles.ResultFullName
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

            $WorkingFiles | ForEach-Object {
                if($_.ResultShortName -ne "ZYX"){
                    $_.ResultFullName = $_.ResultShortName
                }
            }
            Push-Location $BlaDrive
            $meta = .\exiftool.exe "$($WorkingFiles.ResultFullName)" -J | ConvertFrom-Json
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

            Remove-Item -LiteralPath $WorkingFiles.ResultFullName
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

            $WorkingFiles | ForEach-Object {
                if($_.ResultShortName -ne "ZYX"){
                    $_.ResultFullName = $_.ResultShortName
                }
            }
            Push-Location $BlaDrive
            $meta = .\exiftool.exe "$($WorkingFiles.ResultFullName)" -J | ConvertFrom-Json
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

            Remove-Item -LiteralPath $WorkingFiles.ResultFullName
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

            $WorkingFiles | ForEach-Object {
                if($_.ResultShortName -ne "ZYX"){
                    $_.ResultFullName = $_.ResultShortName
                }
            }
            Push-Location $BlaDrive
            $meta = .\exiftool.exe "$($WorkingFiles.ResultFullName)" -J | ConvertFrom-Json
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

            Remove-Item -LiteralPath $WorkingFiles.ResultFullName
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

            $WorkingFiles | ForEach-Object {
                if($_.ResultShortName -ne "ZYX"){
                    $_.ResultFullName = $_.ResultShortName
                }
            }
            Push-Location $BlaDrive
            $meta = .\exiftool.exe "$($WorkingFiles.ResultFullName)" -J | ConvertFrom-Json
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

            Remove-Item -LiteralPath $WorkingFiles.ResultFullName
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

            $WorkingFiles | ForEach-Object {
                if($_.ResultShortName -ne "ZYX"){
                    $_.ResultFullName = $_.ResultShortName
                }
            }
            Push-Location $BlaDrive
            $meta = .\exiftool.exe "$($WorkingFiles.ResultFullName)" -J | ConvertFrom-Json
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

            Remove-Item -LiteralPath $WorkingFiles.ResultFullName
        }
    }
    It "No problems with SpecChars" {
        # $script:Debug = 1
        $UserParams.InputPath = @("$BlaDrive\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©","$BlaDrive\file specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©.jpg")
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
        $test | Should Be 0

        $WorkingFiles | ForEach-Object {
            if($_.ResultShortName -ne "ZYX"){
                $_.ResultFullName = $_.ResultShortName
            }
        }
        Push-Location $BlaDrive
        foreach($i in $WorkingFiles.ResultFullName){
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
    It "No problem with long paths" {
        # $script:Debug = 1
        $UserParams.InputPath = @("$BlaDrive\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND","$BlaDrive\file_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_before_thEND.jpg")
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
        $test | Should Be 0

        $WorkingFiles | ForEach-Object {
            if($_.ResultShortName -ne "ZYX"){
                $_.ResultFullName = $_.ResultShortName
            }
        }
        Push-Location $BlaDrive
        foreach($i in $WorkingFiles.ResultFullName){
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
            Magick =                "$BlaDrive\magick.exe"
            MagickThreads =         12
        }
    }

    Context "Basics" {
        It "Throw if no/wrong param" {
            {Start-Recycling} | Should Throw
            {Start-Recycling -WorkingFiles @()} | Should Throw
        }
        It "Return no errors if all goes well" {
            # $script:Debug = 1
            $WorkingFiles = @(Get-InputFiles -UserParams $UserParams)
            Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
            Mock Read-Host {1}
            $test = Start-Recycling -WorkingFiles $WorkingFiles
            Assert-MockCalled Read-Host -Times 1
            $test | Should Be 0
            $bla = (Get-ChildItem $UserParams.InputPath[0] -Filter *.jpg -File).Fullname
            $bla.Length | Should Be $WorkingFiles.Length
        }
    }
    It "No problems with SpecChars" {
        $UserParams.InputPath = @("$BlaDrive\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©","$BlaDrive\file specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©.jpeg")
        $WorkingFiles = @(Get-InputFiles -UserParams $UserParams)
        Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
        Mock Read-Host {1}
        $test = Start-Recycling -WorkingFiles $WorkingFiles
        Assert-MockCalled Read-Host -Times 1
        $test | Should Be 0
        $bla = (Get-ChildItem -LiteralPath $UserParams.InputPath[0] -Filter *.jpg -File).Fullname
        $bla.Length | Should Be $WorkingFiles.Length
    }
    It "No problems with long paths" {
        $UserParams.InputPath = @("$BlaDrive\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND")
        $WorkingFiles = @(Get-InputFiles -UserParams $UserParams)
        Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles
        Mock Read-Host {1}
        $test = Start-Recycling -WorkingFiles $WorkingFiles
        Assert-MockCalled Read-Host -Times 3
        $test | Should Be 0
        $bla = (Get-ChildItem $UserParams.InputPath[0] -Filter *.jpg -File).Fullname
        $bla.Length | Should Be $WorkingFiles.Length
    }
}

<# TODO: Mock everything to see if params call everything correctly.
    Describe "Start-Everything" {

    }
#>