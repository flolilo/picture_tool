﻿#requires -version 3

<#
    .SYNOPSIS
        Tool to convert images to JPEGs - and transfering their metadata.
    .DESCRIPTION
        This tool uses ImageMagick and ExifTool.
    .NOTES
        Version:    3.1
        Date:       2018-03-13
        Author:     flolilo

    .INPUTS
        files,
        optional: picture_tool_vars.json, if -EXIFManipulation is enabled.
    .OUTPUTS
        JPEGs of the input-files with -Convert2JPEG,
        otherwise the same files.

    .PARAMETER InputPath
        Path to convert files from. Or file(s).
    .PARAMETER Convert2JPEG
        1 enables (default), 0 disables.
        Enable conversion to JPEG (needed for -Convert* parameters).
    .PARAMETER EXIFManipulation
        1 enables (default), 0 disables.
        Enable EXIF manipulation (needed for -EXIF* parameters).
    .PARAMETER EXIFTransferOnly
        1 enables, 0 disables (default).
        Only transfer metadata from one file to an already existing JPEG.
    .PARAMETER EXIFDeleteAll
        1 enables, 0 disables (default).
        1 deletes all non-camera metadata, 2 deletes all metadata (accumulative with -EXIFAddCopyright).
    .PARAMETER EXIFAddCopyright
        1 enables, 0 disables (default).
        Add copyright to the metadata (accumulatove with -EXIFDeleteAll).
    .PARAMETER EXIFPresetName
        If you use a JSON for storing your copyright variables, specify the preset name here (default: default).
    .PARAMETER EXIFArtistName
        Specify the artist name. Overrides JSON parameters.
    .PARAMETER EXIFCopyrightText
        Specify the copyright text. Overrides JSON parameters.
    .PARAMETER Formats
        default: *.TIF for -Convert2JPEG, *.JP(E)G if not.
        All formats to process, e.g. @("*.jpg","*.tif").
    .PARAMETER ConvertQuality
        default: 92
        JPEG quality. See ImageMagick's CLI options for that.
    .PARAMETER ConvertRemoveSource
        1 enables (default), 0 disables.
        Remove TIFs to Recycle Bin after conversion.
    .PARAMETER Convert2SRGB
        1 enables, 0 disables (default).
        Convert files to sRGB - could lead to (slight) color shifts!
    .PARAMETER ConvertScaling
        default: 100
        Scaling of picture with Lanczos filter. Valid values: 1-100, default: 100 (no scaling).
    .PARAMETER EXIFtool
        Path to exiftool.exe.
    .PARAMETER Magick
        Path to magick.exe.
    .PARAMETER MagickThreads
        default: 12
        Thread-Count for conversion. Valid range: 1-48.
    .PARAMETER Debug
        default: 0
        1 stops after each step, 2 additionally outputs some commands.

    .EXAMPLE
        XYZtoJPEG -InputPath D:\MyImages -Formats @("*.jpg","*.tif") -ConvertQuality 70 -ConvertRemoveSource 0 -Convert2SRGB 0
#>
param(
    [ValidateNotNullOrEmpty()]
    [array]$InputPath =             @("$((Get-Location).Path)"),
    [ValidateRange(0,1)]
    [int]$Convert2JPEG =            1,
    [ValidateRange(0,1)]
    [int]$EXIFManipulation =        1,
    [ValidateRange(0,1)]
    [ValidateScript({if($Convert2JPEG -eq 1 -and $_ -eq 1){Throw 'Cannot convert and purely transfer at the same time!'}else{$true}})]
    [int]$EXIFTransferOnly =        0,
    [ValidateRange(0,2)]
    [int]$EXIFDeleteAll =           0,
    [ValidateRange(0,1)]
    [int]$EXIFAddCopyright =        0,
    [string]$EXIFPresetName =       "default",
    [string]$EXIFArtistName =       "",
    [string]$EXIFCopyrightText =    "",
    [ValidateNotNullOrEmpty()]
    [array]$Formats =               $(if($Convert2JPEG -eq 1){@("*.tif")}elseif($EXIFTransferOnly -eq 1){@("*")}else{@("*.jpeg","*.jpg")}),
    [ValidateRange(0,100)]
    [int]$ConvertQuality =          92,
    [ValidateRange(0,1)]
    [int]$ConvertRemoveSource =     1,
    [ValidateRange(0,1)]
    [int]$Convert2SRGB =            0,
    [ValidateRange(1,100)]
    [int]$ConvertScaling =          100,
    [string]$EXIFtool =             "$($PSScriptRoot)\exiftool.exe",
    [string]$Magick =               "$($PSScriptRoot)\ImageMagick\magick.exe",
    [ValidateRange(1,48)]
    [int]$MagickThreads =           12,
    [int]$Debug =                   0
)
# DEFINITION: Combine all parameters into a hashtable, then delete the parameter variables:
    [hashtable]$UserParams = @{
        InputPath =             $InputPath
        Convert2JPEG =          $Convert2JPEG
        EXIFManipulation =      $EXIFManipulation
        EXIFTransferOnly =      $EXIFTransferOnly
        EXIFDeleteAll =         $EXIFDeleteAll
        EXIFAddCopyright =      $EXIFAddCopyright
        EXIFPresetName =        $EXIFPresetName
        EXIFArtistName =        $EXIFArtistName
        EXIFCopyrightText =     $EXIFCopyrightText
        Formats =               $Formats
        ConvertQuality =        $ConvertQuality
        ConvertRemoveSource =   $ConvertRemoveSource
        Convert2SRGB =          $Convert2SRGB
        ConvertScaling =        $ConvertScaling
        EXIFtool=               $EXIFtool
        Magick =                $Magick
        MagickThreads =         $MagickThreads
        }
    Remove-Variable -Name InputPath,Convert2JPEG,EXIFManipulation,EXIFTransferOnly,EXIFDeleteAll,EXIFAddCopyright,EXIFPresetName,EXIFArtistName,EXIFCopyrightText,Formats,ConvertQuality,ConvertRemoveSource,Convert2SRGB,ConvertScaling,EXIFtool,Magick,MagickThreads

# DEFINITION: Get all error-outputs in English:
    [Threading.Thread]::CurrentThread.CurrentUICulture = 'en-US'
# DEFINITION: Hopefully avoiding errors by wrong encoding now:
    $OutputEncoding = New-Object -TypeName System.Text.UTF8Encoding
# DEFINITION: Load Module "Recycle" for moving files to bin instead of removing completely.
    try{
        Import-Module -Name "Recycle" -NoClobber -Global -ErrorAction Stop
    }catch{
        try{
            [string]$PoshRSJobPath = Get-ChildItem -LiteralPath $PSScriptRoot\Modules\Recycle -Recurse -Filter Recycle.psm1 -ErrorAction Stop | Select-Object -ExpandProperty FullName
            Import-Module $PoshRSJobPath -NoClobber -Global -ErrorAction Stop
        }catch{
            Write-Host "Could not load Module `"Recycle`" - Please install it in an " -ForegroundColor Red -NoNewline
            Write-Host "administrative console " -ForegroundColor Yellow -NoNewline
            Write-Host "via " -ForegroundColor Red -NoNewline
            Write-Host "Install-Module Recycle" -NoNewline
            Write-Host ", download it from " -ForegroundColor Red -NoNewline
            Write-Host "github.com/bdukes/PowerShellModules/tree/master/Recycle " -NoNewline
            Write-Host "and install it to " -ForegroundColor Red -NoNewline
            Write-Host "<SCRIPT_PATH>\Modules\Recycle\<VERSION.NUMBER>" -NoNewline -ForegroundColor Gray
            Write-Host "." -ForegroundColor Red
            Pause
            Exit
        }
    }
# DEFINITION: version number:
    $VersionNumber = "v3.1 - 2018-03-13"


# ==================================================================================================
# ==============================================================================
#    Defining generic functions:
# ==============================================================================
# ==================================================================================================

# DEFINITION: Making Write-ColorOut much, much faster:
Function Write-ColorOut(){
    <#
        .SYNOPSIS
            A faster version of Write-ColorOut
        .DESCRIPTION
            Using the [Console]-commands to make everything faster.
        .NOTES
            Date: 2018-03-12
        
        .PARAMETER Object
            String to write out
        .PARAMETER ForegroundColor
            Color of characters. If not specified, uses color that was set before calling. Valid: White (PS-Default), Red, Yellow, Cyan, Green, Gray, Magenta, Blue, Black, DarkRed, DarkYellow, DarkCyan, DarkGreen, DarkGray, DarkMagenta, DarkBlue
        .PARAMETER BackgroundColor
            Color of background. If not specified, uses color that was set before calling. Valid: DarkMagenta (PS-Default), White, Red, Yellow, Cyan, Green, Gray, Magenta, Blue, Black, DarkRed, DarkYellow, DarkCyan, DarkGreen, DarkGray, DarkBlue
        .PARAMETER NoNewLine
            When enabled, no line-break will be created.

        .EXAMPLE
            Just use it like Write-ColorOut.
    #>
    param(
        [string]$Object = "Write-ColorOut was called, but no string was transfered.",

        [ValidateSet("DarkBlue","DarkGreen","DarkCyan","DarkRed","Blue","Green","Cyan","Red","Magenta","Yellow","Black","DarkGray","Gray","DarkYellow","White","DarkMagenta")]
        [string]$ForegroundColor,

        [ValidateSet("DarkBlue","DarkGreen","DarkCyan","DarkRed","Blue","Green","Cyan","Red","Magenta","Yellow","Black","DarkGray","Gray","DarkYellow","White","DarkMagenta")]
        [string]$BackgroundColor,

        [switch]$NoNewLine=$false,

        [ValidateRange(0,48)]
        [int]$Indentation=0
    )

    if($ForegroundColor.Length -ge 3){
        $old_fg_color = [Console]::ForegroundColor
        [Console]::ForegroundColor = $ForegroundColor
    }
    if($BackgroundColor.Length -ge 3){
        $old_bg_color = [Console]::BackgroundColor
        [Console]::BackgroundColor = $BackgroundColor
    }
    if($Indentation -gt 0){
        [Console]::CursorLeft = $Indentation
    }

    if($NoNewLine -eq $false){
        [Console]::WriteLine($Object)
    }else{
        [Console]::Write($Object)
    }
    
    if($ForegroundColor.Length -ge 3){
        [Console]::ForegroundColor = $old_fg_color
    }
    if($BackgroundColor.Length -ge 3){
        [Console]::BackgroundColor = $old_bg_color
    }
}

# DEFINITION: For the auditory experience:
Function Start-Sound(){
    <#
        .SYNOPSIS
            Gives auditive feedback for fails and successes
        .DESCRIPTION
            Uses SoundPlayer and Windows's own WAVs to play sounds.
        .NOTES
            Date: 2018-03-12

        .PARAMETER Success
            1 plays Windows's "tada"-sound, 0 plays Windows's "chimes"-sound.
        
        .EXAMPLE
            For success: Start-Sound 1
        .EXAMPLE
            For fail: Start-Sound 0
    #>
    param(
        [int]$Success = $(return $false)
    )
    try{
        $sound = New-Object System.Media.SoundPlayer -ErrorAction stop
        if($Success -eq 1){
            $sound.SoundLocation = "C:\Windows\Media\tada.wav"
        }else{
            $sound.SoundLocation = "C:\Windows\Media\chimes.wav"
        }
        $sound.Play()
    }catch{
        Write-Output "`a"
    }
}

# DEFINITION: Pause in Debug:
Function Invoke-Pause(){
    if($script:Debug -ne 0){
        Pause
    }
}

# DEFINITION: Exit the program (and close all windows) + option to pause before exiting.
Function Invoke-Close(){
    param(
        [ValidateRange(1,999999999)]
        [int]$PSPID = 999999999
    )
    Write-ColorOut "Exiting - This could take some seconds. Please do not close this window!" -ForegroundColor Magenta
    if($PSPID -ne 999999999){
        Stop-Process -Id $PSPID -ErrorAction SilentlyContinue
    }
    if($script:Debug -gt 0){
        Pause
    }

    $Host.UI.RawUI.WindowTitle = "Windows PowerShell"
    Exit
}

# DEFINITION: Start equivalent to PreventSleep.ps1:
Function Invoke-PreventSleep(){
    <#
        .NOTES
            v1.0 - 2018-02-22
    #>
    Write-ColorOut "$(Get-CurrentDate)  --  Starting preventsleep-script..." -ForegroundColor Cyan

$standby = @'
    # DEFINITION: For button-emulation:
    Write-Host "(PID = $("{0:D8}" -f $pid))" -ForegroundColor Gray
    $MyShell = New-Object -ComObject "Wscript.Shell"
    while($true){
        # DEFINITION:/CREDIT: https://superuser.com/a/1023836/703240
        $MyShell.sendkeys("{F15}")
        Start-Sleep -Seconds 90
    }
'@
    $standby = [System.Text.Encoding]::Unicode.GetBytes($standby)
    $standby = [Convert]::ToBase64String($standby)

    [int]$preventstandbyid = (Start-Process powershell -ArgumentList "-EncodedCommand $standby" -WindowStyle Hidden -PassThru).Id
    if($script:Debug -gt 0){
        Write-ColorOut "preventsleep-PID is $("{0:D8}" -f $preventstandbyid)" -ForegroundColor Gray -BackgroundColor DarkGray -Indentation 4
    }
    Start-Sleep -Milliseconds 25
    if((Get-Process -Id $preventstandbyid -ErrorVariable SilentlyContinue).count -ne 1){
        Write-ColorOut "Cannot prevent standby" -ForegroundColor Magenta -Indentation 4
        Start-Sleep -Seconds 3
    }

    return $preventstandbyid
}

# DEFINITION: Getting date and time in pre-formatted string:
Function Get-CurrentDate(){
    return $(Get-Date -Format "yy-MM-dd HH:mm:ss")
}


# ==================================================================================================
# ==============================================================================
#    Defining specific functions:
# ==============================================================================
# ==================================================================================================

# DEFINITION: Test the paths of the tools:
Function Test-EXEPaths(){
    param(
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams = $(throw 'UserParams is required by Test-EXEPaths')
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Testing EXE-paths..." -ForegroundColor Cyan

    # DEFINITION: Search for exiftool:
    if((Test-Path -LiteralPath $UserParams.EXIFtool -PathType Leaf) -eq $false){
        if((Test-Path -LiteralPath "$($PSScriptRoot)\exiftool.exe" -PathType Leaf) -eq $true){
            [string]$UserParams.EXIFtool = "$($PSScriptRoot)\exiftool.exe"
        }else{
            Write-ColorOut "Exiftool not found - aborting!" -ForegroundColor Red -Indentation 2
            Start-Sound -Success 0
            Start-Sleep -Seconds 2
            return $false
        }
    }
    if((Test-Path -LiteralPath $UserParams.Magick -PathType Leaf) -eq $false){
        if((Test-Path -LiteralPath "$($PSScriptRoot)\Magick.exe" -PathType Leaf) -eq $true){
            [string]$UserParams.Magick = "$($PSScriptRoot)\Magick.exe"
        }else{
            Write-ColorOut "ImageMagick not found - aborting!" -ForegroundColor Red -Indentation 2
            Start-Sound -Success 0
            Start-Sleep -Seconds 2
            return $false
        }
    }

    return $UserParams
}

# DEFINITION: Get files:
Function Get-InputFiles(){
    param(
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams = $(throw 'UserParams is required by Get-InputFiles')
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Search files in InputPath(s)..." -ForegroundColor Cyan
    $sw = [diagnostics.stopwatch]::StartNew()

    Function Test-Duplicates(){
        param(
            [Parameter(Mandatory=$true)]
            [string]$Directory,
            [Parameter(Mandatory=$true)]
            [string]$BaseName
        )
    
        [string]$inter = "$($Directory)\$($BaseName).jpg"
        if((Test-Path -LiteralPath $inter -PathType Leaf) -eq $true){
            [int]$k = 1
            while($true){
                [string]$inter = "$($Directory)\$($BaseName)_$($k).jpg"
                if((Test-Path -LiteralPath $inter -PathType Leaf) -eq $true){
                    $k++
                    continue
                }else{
                    [string]$result = $inter
                    break
                }
            }
        }else{
            [string]$result = $inter
        }
    
        return $result
    }

    [array]$WorkingFiles = @()
    for($i=0; $i -lt $UserParams.InputPath.Length; $i++){
        if($sw.Elapsed.TotalMilliseconds -ge 750){
            Write-Progress -Id 1 -Activity "Searching files..." -Status "$($UserParams.InputPath[$i])" -PercentComplete $($($i + 1) *100 / $($UserParams.InputPath.Length))
            Write-Progress -id 3 -Activity "Searching files..." -Status "File # $($WorkingFiles.Length)" -PercentComplete -1
            $sw.Reset()
            $sw.Start()
        }

        $UserParams.InputPath[$i] = Resolve-Path -Path $UserParams.InputPath[$i] | Select-Object -ExpandProperty Path
        if((Test-Path -LiteralPath $UserParams.InputPath[$i] -PathType Container) -eq $true){
            foreach($k in $UserParams.Formats){
                if($sw.Elapsed.TotalMilliseconds -ge 750){
                    Write-Progress -Id 2 -Activity "Searching files..." -Status "Format #$($k +1)/$($UserParams.Formats.Length)" -PercentComplete $($($k + 1) *100 / $($UserParams.Formats.Length))
                    Write-Progress -id 3 -Activity "Searching files..." -Status "File # $($WorkingFiles.Length)" -PercentComplete -1
                    $sw.Reset()
                    $sw.Start()
                }

                $WorkingFiles += @(Get-ChildItem -LiteralPath $UserParams.InputPath[$i] -Filter $k | ForEach-Object{
                    [PSCustomObject]@{
                        SourceFullName = $_.FullName
                        SourceName = $_.Name
                        BaseName = $_.BaseName
                        JPEGFullName = $(if($UserParams.Convert2JPEG -eq 1){Test-Duplicates -Directory (Split-Path -Path $_.FullName -Parent) -BaseName $_.BaseName}else{"ZYX"})
                    }
                })
            }
        }elseif((Test-Path -LiteralPath $UserParams.InputPath[$i] -PathType Leaf) -eq $true){
            if($sw.Elapsed.TotalMilliseconds -ge 750){
                Write-Progress -id 3 -Activity "Searching files..." -Status "File # $($WorkingFiles.Length)" -PercentComplete -1
                $sw.Reset()
                $sw.Start()
            }

            $WorkingFiles += @(Get-Item -LiteralPath $UserParams.InputPath[$i] | ForEach-Object {
                [PSCustomObject]@{
                    SourceFullName = $_.FullName
                    SourceName = $_.Name
                    BaseName = $_.BaseName
                    JPEGFullName = $(if($UserParams.Convert2JPEG -eq 1){Test-Duplicates -Directory (Split-Path -Path $_.FullName -Parent) -BaseName $_.BaseName}else{"ZYX"})
                }
            })
        }else{
            Write-ColorOut "$($UserParams.InputPath) not found - aborting!" -ForegroundColor Red -Indentation 2
            Start-Sound -Success 0
            Start-Sleep -Seconds 3
            return $false
        }
    }
    Write-Progress -Id 3 -Activity "Searching files..." -Status "Done!" -Completed
    Write-Progress -Id 2 -Activity "Searching files..." -Status "Done!" -Completed
    Write-Progress -Id 1 -Activity "Searching files..." -Status "Done!" -Completed

    if($UserParams.EXIFTransferOnly -eq 1){
        [array]$original = @()
        [array]$jpg = @()
        [array]$sourcename = @()
        [array]$WorkingFiles = @($WorkingFiles | Group-Object -Property BaseName | Where-Object {$_.Count -gt 1})
        for($i=0; $i -lt $WorkingFiles.Length; $i++){
            if($WorkingFiles[$i].Group.SourceFullName.Length -gt 2){
                [array]$inter = @($WorkingFiles[$i].Group.SourceFullName | Where-Object {$_ -notmatch '\.jpg$' -and $_ -notmatch '\.jpeg$'})

                Write-ColorOut "More than one source-file found. Please choose between:" -ForegroundColor Yellow -Indentation 2
                for($k=0; $k -lt $inter.Length; $k++){
                    Write-ColorOut "$k - $($inter[$k])" -ForegroundColor Gray -Indentation 4
                }
                [int]$choice = 999
                while($choice -notin (0..$inter.Length)){
                    try{
                        Write-ColorOut "Which one do you want?`t" -ForegroundColor Yellow -NoNewLine -Indentation 2
                        [int]$choice = Read-Host
                    }catch{
                        Write-ColorOut "Wrong input!" -ForegroundColor Red -Indentation 4
                        continue
                    }
                }
                $original += @($inter[$choice])
            }else{
                $original += @($WorkingFiles[$i].Group.SourceFullName | Where-Object {$_ -notmatch '\.jpg$' -and $_ -notmatch '\.jpeg$'})
            }
            $jpg += @($WorkingFiles[$i].Group.SourceFullName | Where-Object {$_ -match '\.jpg$' -or $_ -match '\.jpeg$'})
            $sourcename += @($WorkingFiles[$i].Group.SourceName)
        }
        [array]$WorkingFiles = @()
        for($i=0; $i -lt $original.Length; $i++){
            $WorkingFiles += @(
                [PSCustomObject]@{
                    SourceFullName = $original[$i]
                    JPEGFullName = $jpg[$i]
                    SourceName = $sourcename[$i]
                }
                Write-ColorOut "From:`t$($original[$i].Replace("$($UserParams.InputPath)","."))" -ForegroundColor Gray -Indentation 4
                Write-ColorOut "To:`t`t$($jpg[$i].Replace("$($UserParams.InputPath)","."))" -Indentation 4
            )
        }
        if($script:Debug -gt 1){
            $WorkingFiles | Format-Table -AutoSize
        }
        Write-ColorOut "Continue?`t" -ForegroundColor Yellow -NoNewLine -Indentation 2
        Pause
    }
    

    return $WorkingFiles
}

# DEFINITION: Convert from XYZ to JPEG:
Function Start-Converting(){
    param(
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams = $(throw 'UserParams is required by Start-Converting'),
        [ValidateNotNullOrEmpty()]
        [array]$WorkingFiles = $(throw 'WorkingFiles is required by Start-Converting')
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Converting files to JPEG..." -ForegroundColor Cyan
    $sw = [diagnostics.stopwatch]::StartNew()
    [int]$errorcounter = 0
    if($script:Debug -gt 0){
        [string]$debuginter = "$((Get-Location).Path)"
    }

    $WorkingFiles | ForEach-Object -Begin {
        [int]$counter = @(Get-Process -Name magick -ErrorAction SilentlyContinue).count
        [int]$i = 1
        Write-Progress -Activity "Converting files to JPEG (-q = $($UserParams.ConvertQuality))..." -Status "Starting..." -PercentComplete -1
        $sw.Reset()
        $sw.Start()
    } -Process {
        while($counter -ge $UserParams.MagickThreads){
            $counter = @(Get-Process -Name magick -ErrorAction SilentlyContinue).count
            Start-Sleep -Milliseconds 25
        }
        if($sw.Elapsed.TotalMilliseconds -ge 750){
            Write-Progress -Activity "Converting files to JPEG (-q = $($UserParams.ConvertQuality))..." -Status "File #$i - $($_.SourceName)" -PercentComplete $($i * 100 / $WorkingFiles.Length) 
            $sw.Reset()
            $sw.Start()
        }

        # TODO: "-layers merge" for layered images
        [string]$ArgList = "convert -quality $($UserParams.ConvertQuality) -depth 8 `"$($_.SourceFullName)`""
        if($UserParams.Convert2SRGB -eq 1){
            $ArgList += " -profile `"C:\Windows\System32\spool\drivers\color\sRGB Color Space Profile.icm`" -colorspace sRGB"
        }
        if($UserParams.ConvertScaling -ne 100){
            $ArgList += " -filter Lanczos -resize $($UserParams.ConvertScaling)%"   
        }
        $ArgList += " -quiet `"$($_.JPEGFullName)`""

        if($script:Debug -gt 0){
            Write-ColorOut $ArgList.Replace("$debuginter",".") -ForegroundColor Gray -Indentation 4
        }

        try {
            Start-Process -FilePath $UserParams.Magick -ArgumentList $ArgList -NoNewWindow
        }catch{
            Write-ColorOut "`"$ArgList`" failed!" -ForegroundColor Magenta -Indentation 2
            $errorcounter++
        }

        $counter++
        $i++
    } -End {
        while($counter -gt 0){
            $counter = @(Get-Process -Name magick -ErrorAction SilentlyContinue).count
            Start-Sleep -Milliseconds 10
        }
        Write-Progress -Activity "Converting files to JPEG (-q = $($UserParams.ConvertQuality))..." -Status "Done!" -Completed
    }

    return $errorcounter
}

# DEFINITION: Get EXIF values from JSON or console:
Function Get-EXIFValues(){
    param(
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams = $(throw 'UserParams is required by Get-EXIFValues')
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Getting EXIF-values..." -ForegroundColor Cyan

    if($UserParams.EXIFArtistName.Length -lt 1 -or $UserParams.EXIFCopyrightText.Length -lt 1){
        if((Test-Path -LiteralPath "$($PSScriptRoot)\picture_tool_vars.json" -PathType Leaf) -eq $true){
            try{
                [array]$JSON = Get-Content -LiteralPath "$($PSScriptRoot)\picture_tool_vars.json" -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-JSON -ErrorAction Stop
                if($UserParams.EXIFPresetName.Length -gt 0 -and $UserParams.EXIFPresetName -in $JSON.preset){
                    [array]$JSON = $JSON | Where-Object {$_.preset -eq $UserParams.EXIFPresetName}
                }else{
                    Write-ColorOut "Could not find preset `"$UserParams.EXIFPresetName`" - changed to `"default`"." -ForegroundColor Magenta -Indentation 4
                    [array]$JSON = $JSON | Where-Object {$_.preset -eq "default"}
                }
                [array]$JSON = $JSON.values
    
                [string]$UserParams.EXIFArtistName = $JSON.artist_name
                [string]$UserParams.EXIFCopyrightText = $JSON.copyright_text
            }catch{
                Write-ColorOut "Could not load $($PSScriptRoot)\picture_tool_vars.json" -ForegroundColor Magenta -Indentation 2
                try{
                    Write-ColorOut "Enter artist name here:`t" -NoNewLine -Indentation 4
                    [string]$UserParams.EXIFArtistName = Read-Host
                }catch{
                    continue
                }
                try{
                    Write-ColorOut "Enter copyright text here:`t" -NoNewLine -Indentation 4
                    [string]$UserParams.EXIFCopyrightText = Read-Host
                }catch{
                    continue
                }
            }
        }else{
            try{
                Write-ColorOut "Enter artist name here:`t" -NoNewLine -Indentation 4
                [string]$UserParams.EXIFArtistName = Read-Host
            }catch{
                continue
            }
            try{
                Write-ColorOut "Enter copyright text here:`t" -NoNewLine -Indentation 4
                [string]$UserParams.EXIFCopyrightText = Read-Host
            }catch{
                continue
            }
        }
    }

    return $UserParams
}

# DEFINITION: EXIF manipulation (transfer / modify):
Function Start-EXIFManipulation(){
    param(
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams = $(throw 'UserParams is required by Start-EXIFManipulation'),
        [ValidateNotNullOrEmpty()]
        [array]$WorkingFiles = $(throw 'WorkingFiles is required by Start-EXIFManipulation')
    )
    # DEFINITION: Create Exiftool process:
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $UserParams.EXIFtool
    $psi.Arguments = "-stay_open True -@ -"
    $psi.UseShellExecute = $false
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $exiftoolproc = [System.Diagnostics.Process]::Start($psi)
    Start-Sleep -Seconds 1

    # DEFINITION: set string in correlation to mode:
    [string]$inter = $(
        if($UserParams.Convert2JPEG -eq 1 -or $UserParams.EXIFTransferOnly -eq 1){
                if($UserParams.EXIFDeleteAll -eq 0 -and $UserParams.EXIFAddCopyright -eq 0){"transfer EXIF (keep all as-is)"}
            elseif($UserParams.EXIFDeleteAll -eq 0 -and $UserParams.EXIFAddCopyright -eq 1){"transfer EXIF (add copyright)"}
            elseif($UserParams.EXIFDeleteAll -eq 1 -and $UserParams.EXIFAddCopyright -eq 0){"transfer EXIF (delete non-cam EXIF)"}
            elseif($UserParams.EXIFDeleteAll -eq 1 -and $UserParams.EXIFAddCopyright -eq 1){"transfer EXIF (delete non-cam EXIF, add copyright)"}
            elseif($UserParams.EXIFDeleteAll -eq 2 -and $UserParams.EXIFAddCopyright -eq 0){"transfer EXIF (delete all EXIF)"}
            elseif($UserParams.EXIFDeleteAll -eq 2 -and $UserParams.EXIFAddCopyright -eq 1){"transfer EXIF (delete all EXIF, add copyright)"}
        }else{
            elseif($UserParams.EXIFDeleteAll -eq 0 -and $UserParams.EXIFAddCopyright -eq 0){"modify EXIF (keep all as-is)"}
            elseif($UserParams.EXIFDeleteAll -eq 0 -and $UserParams.EXIFAddCopyright -eq 1){"modify EXIF (add copyright)"}
            elseif($UserParams.EXIFDeleteAll -eq 1 -and $UserParams.EXIFAddCopyright -eq 0){"modify EXIF (delete non-cam EXIF)"}
            elseif($UserParams.EXIFDeleteAll -eq 1 -and $UserParams.EXIFAddCopyright -eq 1){"modify EXIF (delete non-cam EXIF, add copyright)"}
            elseif($UserParams.EXIFDeleteAll -eq 2 -and $UserParams.EXIFAddCopyright -eq 0){"modify EXIF (delete all EXIF)"}
            elseif($UserParams.EXIFDeleteAll -eq 2 -and $UserParams.EXIFAddCopyright -eq 1){"modify EXIF (delete all EXIF, add copyright)"}
        }
    )

    Write-ColorOut "$(Get-CurrentDate)  --  $inter..." -ForegroundColor Cyan
    $sw = [diagnostics.stopwatch]::StartNew()
    if($script:Debug -gt 0){
        [string]$debuginter = "$((Get-Location).Path)"
    }
    [int]$errorcounter = 0

    # DEFINITION: Pass arguments to Exiftool:
    for($i=0; $i -lt $WorkingFiles.length; $i++){
        if($sw.Elapsed.TotalMilliseconds -ge 750){
            Write-Progress -Activity "$inter..." -Status "File # $i - $($WorkingFiles[$i].SourceName)" -PercentComplete $($i * 100 / $WorkingFiles.length)
            $sw.Reset()
            $sw.Start()
        }

        # DEFINITION: Set arguments for different purposes:
            if($inter -eq "transfer EXIF (keep all as-is)"){
                [string]$ArgList = "-tagsfromfile`n$($WorkingFiles[$i].SourceFullName)`n-All:All`n-xresolution=300`n-yresolution=300`n-EXIF:Software=`n-Photoshop:All=`n-Adobe:All=`n-XMP:CreatorTool=`n-XMP:HistoryAction=`n-XMP:HistoryInstanceID=`n-XMP:HistorySoftwareAgent=`n-XMP:HistoryWhen=`n-XMP:InstanceID=`n-XMP:LegacyIPTCDigest=`n-XMP:DocumentID=`n-XMP:OriginalDocumentID=`n-XMP:HistoryChanged=`n-TagsFromFile`n$($WorkingFiles[$i].SourceFullName)`n-IPTC:Keywords`n-IPTC:By-Line`n-IPTC:CopyrightNotice`n-IPTC:ObjectName`n-overwrite_original`n$($WorkingFiles[$i].JPEGFullName)"
            }elseif($inter -eq "transfer EXIF (add copyright)"){
                [string]$ArgList = "-tagsfromfile`n$($WorkingFiles[$i].SourceFullName)`n-All:All`n-xresolution=300`n-yresolution=300`n-artist=$($UserParams.EXIFArtistName)`n-copyright=$($UserParams.EXIFCopyrightText)`n-IPTC:By-Line=$($UserParams.EXIFArtistName)`n-IPTC:CopyrightNotice=$($UserParams.EXIFCopyrightText)`n-EXIF:Software=`n-Photoshop:All=`n-Adobe:All=`n-XMP:CreatorTool=`n-XMP:HistoryAction=`n-XMP:HistoryInstanceID=`n-XMP:HistorySoftwareAgent=`n-XMP:HistoryWhen=`n-XMP:InstanceID=`n-XMP:LegacyIPTCDigest=`n-XMP:DocumentID=`n-XMP:OriginalDocumentID=`n-XMP:HistoryChanged=`n-TagsFromFile`n$($WorkingFiles[$i].SourceFullName)`n-IPTC:Keywords`n-IPTC:By-Line`n-IPTC:CopyrightNotice`n-IPTC:ObjectName`n-overwrite_original`n$($WorkingFiles[$i].JPEGFullName)"
            }elseif($inter -eq "transfer EXIF (delete non-cam EXIF)"){
                
                [string]$ArgList = "-tagsfromfile`n$($WorkingFiles[$i].SourceFullName)`n-EXIF:All`n-xresolution=300`n-yresolution=300`n-EXIF:Software=`n-Photoshop:All=`n-Adobe:All=`n-XMP:All=`n-IPTC:All=`n-overwrite_original`n$($WorkingFiles[$i].JPEGFullName)"
            }elseif($inter -eq "transfer EXIF (delete non-cam EXIF, add copyright)"){
                [string]$ArgList = "-tagsfromfile`n$($WorkingFiles[$i].SourceFullName)`n-EXIF:All`n-xresolution=300`n-yresolution=300`n-EXIF:Software=`n-Photoshop:All=`n-Adobe:All=`n-XMP:All=`n-IPTC:All=`n-artist=$($UserParams.EXIFArtistName)`n-copyright=$($UserParams.EXIFCopyrightText)`n-IPTC:By-Line=$($UserParams.EXIFArtistName)`n-IPTC:CopyrightNotice=$($UserParams.EXIFCopyrightText)`n-overwrite_original`n$($WorkingFiles[$i].JPEGFullName)"
            }elseif($inter -eq "transfer EXIF (delete all EXIF)"){
                [string]$ArgList = "-xresolution=300`n-yresolution=300`n-All:All=`n-overwrite_original`n$($WorkingFiles[$i].JPEGFullName)"
            }elseif($inter -eq "transfer EXIF (delete all EXIF, add copyright)"){
                [string]$ArgList = "-xresolution=300`n-yresolution=300`n-All:All=`n-artist=$($UserParams.EXIFArtistName)`n-copyright=$($UserParams.EXIFCopyrightText)`n-IPTC:By-Line=$($UserParams.EXIFArtistName)`n-IPTC:CopyrightNotice=$($UserParams.EXIFCopyrightText)`n-overwrite_original`n$($WorkingFiles[$i].JPEGFullName)"
            }elseif($inter -eq "modify EXIF (keep all as-is)"){
                [string]$ArgList = "-xresolution=300`n-yresolution=300`n-EXIF:Software=`n-Photoshop:All=`n-Adobe:All=`n-XMP:CreatorTool=`n-XMP:HistoryAction=`n-XMP:HistoryInstanceID=`n-XMP:HistorySoftwareAgent=`n-XMP:HistoryWhen=`n-XMP:InstanceID=`n-XMP:LegacyIPTCDigest=`n-XMP:DocumentID=`n-XMP:OriginalDocumentID=`n-XMP:HistoryChanged=`n`n-IPTC:Keywords<IPTC:Keywords`n-IPTC:By-Line<IPTC:By-Line`n-IPTC:CopyrightNotice<IPTC:CopyrightNotice`n-IPTC:ObjectName<IPTC:ObjectName`n-overwrite_original`n$($WorkingFiles[$i].SourceFullName)"
            }elseif($inter -eq "modify EXIF (add copyright)"){
                [string]$ArgList = "-xresolution=300`n-yresolution=300`n-EXIF:Software=`n-Photoshop:All=`n-Adobe:All=`n-XMP:CreatorTool=`n-XMP:HistoryAction=`n-XMP:HistoryInstanceID=`n-XMP:HistorySoftwareAgent=`n-XMP:HistoryWhen=`n-XMP:InstanceID=`n-XMP:LegacyIPTCDigest=`n-XMP:DocumentID=`n-XMP:OriginalDocumentID=`n-XMP:HistoryChanged=`n`n-IPTC:Keywords<IPTC:Keywords`n-IPTC:By-Line<IPTC:By-Line`n-IPTC:CopyrightNotice<IPTC:CopyrightNotice`n-IPTC:ObjectName<IPTC:ObjectName`n-artist=$($UserParams.EXIFArtistName)`n-copyright=$($UserParams.EXIFCopyrightText)`n-IPTC:By-Line=$($UserParams.EXIFArtistName)`n-IPTC:CopyrightNotice=$($UserParams.EXIFCopyrightText)`n-overwrite_original`n$($WorkingFiles[$i].SourceFullName)"
            }elseif($inter -eq "modify EXIF (delete non-cam EXIF)"){
                [string]$ArgList = "-EXIF:All<EXIF:All`n-xresolution=300`n-yresolution=300`n-EXIF:Software=`n-Photoshop:All=`n-Adobe:All=`n-XMP:All=`n-IPTC:All=`n-overwrite_original`n$($WorkingFiles[$i].SourceFullName)"
            }elseif($inter -eq "modify EXIF (delete non-cam EXIF, add copyright)"){
                [string]$ArgList = "-EXIF:All<EXIF:All`n-xresolution=300`n-yresolution=300`n-EXIF:Software=`n-Photoshop:All=`n-Adobe:All=`n-XMP:All=`n-IPTC:All=`n-artist=$($UserParams.EXIFArtistName)`n-copyright=$($UserParams.EXIFCopyrightText)`n-IPTC:By-Line=$($UserParams.EXIFArtistName)`n-IPTC:CopyrightNotice=$($UserParams.EXIFCopyrightText)`n-overwrite_original`n$($WorkingFiles[$i].SourceFullName)"
            }elseif($inter -eq "modify EXIF (delete all EXIF)"){
                [string]$ArgList = "-All:All=`n-xresolution=300`n-yresolution=300`n-overwrite_original`n$($WorkingFiles[$i].SourceFullName)"
            }elseif($inter -eq "modify EXIF (delete all EXIF, add copyright)"){
                [string]$ArgList = "-All:All=`n-xresolution=300`n-yresolution=300`n-artist=$($UserParams.EXIFArtistName)`n-copyright=$($UserParams.EXIFCopyrightText)`n-IPTC:By-Line=$($UserParams.EXIFArtistName)`n-IPTC:CopyrightNotice=$($UserParams.EXIFCopyrightText)`n-overwrite_original`n$($WorkingFiles[$i].SourceFullName)"
            }else{
                Write-ColorOut "Something went wrong!" -ForegroundColor Magenta -Indentation 2
                $errorcounter++
            }

        if($script:Debug -gt 0){
            Write-ColorOut $ArgList.Replace("`n"," ").Replace("$debuginter",".") -ForegroundColor DarkGray -Indentation 4
        }

        $exiftoolproc.StandardInput.WriteLine("$ArgList`n-execute`n")
    }
    $exiftoolproc.StandardInput.WriteLine("-stay_open`nFalse`n")

    [array]$outputerror = @($exiftoolproc.StandardError.ReadToEnd().Split("`r`n",[System.StringSplitOptions]::RemoveEmptyEntries))
    [string]$outputout = $exiftoolproc.StandardOutput.ReadToEnd()
    $outputout = $outputout -replace '========\ ','' -replace '\[1/1]','' -replace '\ \r\n\ \ \ \ '," - " -replace '{ready}\r\n',''
    [array]$outputout = @($outputout.Split("`r`n",[System.StringSplitOptions]::RemoveEmptyEntries))

    $exiftoolproc.WaitForExit()
    Write-Progress -Activity "$inter..." -Status "Complete!" -Completed

    for($i=0; $i -lt $WorkingFiles.length; $i++){
        Write-ColorOut "$($WorkingFiles[$i].SourceName):`t" -ForegroundColor Gray -NoNewLine -Indentation 2
        if($outputerror[$i].Length -gt 0){
            Write-ColorOut "$($outputerror[$i])`t" -ForegroundColor Red -NoNewline
            $errorcounter++
        }
        Write-ColorOut "$($outputout[$i])" -ForegroundColor Yellow
    }

    return $errorcounter
}

# DEFINITION: Recycle:
Function Start-Recycling(){
    param(
        [ValidateNotNullOrEmpty()]
        [array]$WorkingFiles = $(throw 'WorkingFiles is required by Start-Recycling')
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Recycling source-files..." -ForegroundColor Cyan
    $sw = [diagnostics.stopwatch]::StartNew()
    if($script:Debug -gt 0){
        [string]$debuginter = "$((Get-Location).Path)"
    }
    [int]$errorcounter = 0

    $WorkingFiles | ForEach-Object -Begin {
        [int]$i = 1
        Write-Progress -Activity "Recycling source-files..." -Status "File #$i - $($_.SourceName)" -PercentComplete $($i * 100 / $WorkingFiles.Length)
        $sw.Reset()
        $sw.Start()
    } -Process {
        if($sw.Elapsed.TotalMilliseconds -ge 750){
            Write-Progress -Activity "Recycling source-files..." -Status "File #$i - $($_.SourceName)" -PercentComplete $($i * 100 / $WorkingFiles.Length)
            $sw.Reset()
            $sw.Start()
        }

        if($script:Debug -gt 0){
            Write-ColorOut "Remove-ItemSafely `"$($_.SourceFullName.Replace("$debuginter","."))`"" -ForegroundColor Gray -Indentation 4
        }
        try {
            Remove-ItemSafely $_.SourceFullName -ErrorAction Stop
        }catch{
            Write-ColorOut "Could not delete $($_.SourceFullName.Replace("$debuginter","."))" -ForegroundColor Magenta -Indentation 2
            $errorcounter++
        }
        $i++
    } -End {
        Write-Progress -Activity "Recycling source-files..." -Status "Done!" -Completed
    }

    return $errorcounter
}


# DEFINITION: Start everything:
Function Start-Everything(){
    param(
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams = $(throw 'UserParams is required by Start-Everything')
    )
    Write-ColorOut "                                              A" -BackgroundColor DarkGray -ForegroundColor DarkGray
    Write-ColorOut "        flolilo's XYZ to JPEG converter        " -ForegroundColor DarkCyan -BackgroundColor Gray
    Write-ColorOut "               $script:VersionNumber               " -ForegroundColor DarkCyan -BackgroundColor Gray
    Write-ColorOut "(PID = $("{0:D8}" -f $pid))                               `r`n" -ForegroundColor Gray -BackgroundColor DarkGray
    $Host.UI.RawUI.WindowTitle = "XYZ to JPEG converter $script:VersionNumber"

    [int]$preventstandbyid = 999999999
    [int]$preventstandbyid = Invoke-PreventSleep

    $UserParams = Test-EXEPaths -UserParams $UserParams
    if($script:Debug -gt 1){
        $UserParams | Format-List
    }
    if($UserParams -eq $false -or $UserParams.GetType().Name -ne "hashtable"){
        Invoke-Close -PSPID $preventstandbyid
    }
    Invoke-Pause

    [array]$WorkingFiles = @(Get-InputFiles -UserParams $UserParams)
    if($WorkingFiles -eq $false){
        Start-Sound -Success 0
        Invoke-Close -PSPID $preventstandbyid
    }elseif($WorkingFiles.Length -le 0){
        Write-ColorOut "Zero files to process!" -ForegroundColor Yellow -Indentation 2
        Start-Sound -Success 1
        Start-Sleep 2
        Invoke-Close -PSPID $preventstandbyid
    }
    if($script:Debug -gt 1){
        $WorkingFiles | Format-Table -AutoSize
    }
    Invoke-Pause

    if($UserParams.Convert2JPEG -eq 1){
        if((Start-Converting -UserParams $UserParams -WorkingFiles $WorkingFiles) -gt 0){
            Write-ColorOut "Errors occured in conversion" -ForegroundColor Red -Indentation 2
            Start-Sound -Success 0
            Start-Sleep -Seconds 2
            Invoke-Close -PSPID $preventstandbyid
        }
        Invoke-Pause
    }

    if($UserParams.EXIFManipulation -eq 1 -or $UserParams.EXIFTransferOnly -eq 1){
        # DEFINITION: Get EXIF-values from JSON / console:
        if($UserParams.EXIFAddCopyright -eq 1){
            $UserParams = Get-EXIFValues -UserParams $UserParams
            Invoke-Pause
        }

        if((Start-EXIFManipulation -UserParams $UserParams -WorkingFiles $WorkingFiles) -gt 0){
            Write-ColorOut "Errors occured in EXIFManipulation" -ForegroundColor Red -Indentation 2
            Start-Sound -Success 0
            Start-Sleep -Seconds 2
            Invoke-Close -PSPID $preventstandbyid
        }
        Invoke-Pause
    }

    if($UserParams.Convert2JPEG -eq 1 -and $UserParams.ConvertRemoveSource -eq 1){
        if((Start-Recycling -WorkingFiles $WorkingFiles) -gt 0){
            Write-ColorOut "Errors occured during recycling" -ForegroundColor Red -Indentation 2
            Start-Sound -Success 0
            Start-Sleep -Seconds 2
            Invoke-Close -PSPID $preventstandbyid
        }
        Invoke-Pause
    }

    Write-ColorOut "$(Get-CurrentDate)  --  Done!" -ForegroundColor Green
    Start-Sound -Success 1
    Start-Sleep -Seconds 5
    Invoke-Close -PSPID $preventstandbyid
}

Start-Everything -UserParams $UserParams
