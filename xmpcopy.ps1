#requires -version 3
# Copy XMP info from e.g. Capture One's XMP-files to DigiKam-compliant XMP files.
# WARNING: QUICK AND DIRTY SOLUTION! USE AT YOUR OWN RISK!

Write-Host "This tool copies XMP info from e.g. Capture One's XMP-files to e.g. DigiKam-compliant XMP files."
Write-Host "WARNING: QUICK AND DIRTY SOLUTION! USE AT YOUR OWN RISK!"
Start-Sleep -Seconds 2

$paths = @("D:\Bilder\_CANON\Privat","D:\Bilder\_CANON\Professionell")
$paths += "D:\Bilder\_CANON\Projekte"
$Script:InfoPreference = 0

$XMP = @()
foreach($i in $paths){
    Push-Location $i

    $XMP += @(Get-ChildItem .\ -Filter *.xmp -Recurse | Where-Object {$_.FullName -notmatch '^.*\.\w{3}\.xmp$' -and $_.Extension -notmatch '^\.xmp_original$'} | ForEach-Object {
        [PSCustomObject]@{
            XMP = $_.FullName
            original = $null
        }
    })

    Pop-Location
}
$XMP.Length
$XMP | ForEach-Object {
    [array]$original = @(Get-Item $($_.XMP.Replace(".xmp",".*")) | Where-Object {$_.Extension -notmatch '^\.xmp.*$'} | Select-Object -ExpandProperty FullName)
    if($original.Count -gt 1){
        $original = @($original | Where-Object {$_ -notmatch '^.*\.jpg$'})
        if($original.Count -gt 1){
            $original = @($original | Where-Object {$_ -notmatch '^.*\.psd$'})
            if($original.Count -gt 1){
                $original = @($original | Where-Object {$_ -notmatch '^.*\.tif$'})
                if($original.Count -gt 1){
                    $original = @($original | Where-Object {$_ -notmatch '^.*\.psb$'})
                    if($original.Count -gt 1){
                        $original = @($original | Where-Object {$_ -notmatch '^.*\.png$'})
        }}}}
    }
    $_.original = $($original)
}
$XMP | Out-Null
# $XMP | Where-Object {$_.original -eq $null} | Format-List; exit


$XMP = @($XMP | Where-Object {$_.original -ne $null})
$XMP | Out-Null

$XMP = @($XMP | Sort-Object -Property XMP,original)
$XMP | Out-Null

$XMP.Length

# $XMP | Format-List; $XMP.Length; exit
# $XMP | Format-List | Out-File D:\xmp.txt; exit

Function Start-EXIFManipulation(){
    param(
        [ValidateNotNullOrEmpty()]
        [array]$WorkingFiles = $(throw 'WorkingFiles is required by Start-EXIFManipulation')
        )
        [int]$errorcounter = 0
        [int]$successcounter = 0

        # DEFINITION: Create Exiftool process:
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "C:\FFMPEG\binaries\exiftool.exe"
        $psi.Arguments = "-stay_open True -charset utf8 -@ -"
        $psi.UseShellExecute = $false
        $psi.RedirectStandardInput = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        # CREDIT: To get asymmetric buffer readout running (ak.a. unlimited processing) (1/2): https://stackoverflow.com/a/24371479/8013879
        [int]$exiftoolInstanceCount = [Math]::Ceiling($WorkingFiles.Length/100)
        $exiftoolproc = @{}
        $exiftoolStdOutBuilder = @{}
        $exiftoolStdErrBuilder = @{}
        $exiftoolScripBlock = @{}
        $exiftoolStdOutEvent = @{}
        $exiftoolStdErrEvent = @{}
        for($i=0; $i -lt $exiftoolInstanceCount; $i++){
            try{
                $exiftoolproc[$i] = New-Object -TypeName System.Diagnostics.Process -Verbose
                $exiftoolproc[$i].StartInfo = $psi
            }catch{
                write-host "Failed to create System.Diagnostics.Process #$($i.ToString())!" -ForegroundColor Red
                return 1
            }
            try{
                # Creating string builders to store StdOut and StdErr:
                $exiftoolStdOutBuilder[$i] = New-Object -TypeName System.Text.StringBuilder -Verbose
            $exiftoolStdErrBuilder[$i] = New-Object -TypeName System.Text.StringBuilder -Verbose
        }catch{
            write-host "Failed to create System.Text.StringBuilder #$($i.ToString())!" -ForegroundColor Red
            return 1
        }
        try{
            # Adding event handers for StdOut and StdErr:
            $exiftoolScripBlock[$i] = {
                if(-not [String]::IsNullOrEmpty($EventArgs.Data)){
                    $Event.MessageData.AppendLine($EventArgs.Data)
                }
            }
        }catch{
            write-host "Failed to create Event.MessageData.AppendLine #$($i.ToString())!" -ForegroundColor Red
            return 1
        }
        try{
            $exiftoolStdOutEvent[$i] = Register-ObjectEvent -InputObject $exiftoolproc[$i] -Action $exiftoolScripBlock[$i] -EventName 'OutputDataReceived' -MessageData $exiftoolStdOutBuilder[$i] -Verbose
            $exiftoolStdErrEvent[$i] = Register-ObjectEvent -InputObject $exiftoolproc[$i] -Action $exiftoolScripBlock[$i] -EventName 'ErrorDataReceived' -MessageData $exiftoolStdErrBuilder[$i] -Verbose
        }catch{
            write-host "Failed to create Register-ObjectEvent #$($i.ToString())!" -ForegroundColor Red
            return 1
        }
        try{
            [Void]$exiftoolproc[$i].Start()
            $exiftoolproc[$i].BeginOutputReadLine()
            $exiftoolproc[$i].BeginErrorReadLine()
        }catch{
            write-host "Failed to create exiftool-instance #$($i.ToString())!" -ForegroundColor Red
            return 1
        }

        if($script:InfoPreference -gt 0){
            write-host "exiftool instance #$i created!" -ForegroundColor Gray
        }
    }

    # DEFINITION: Set arguments for different purposes:
    [array]$exiftoolArgList = @()
    for($i=0; $i -lt $WorkingFiles.Length; $i++){
        #$exiftoolArgList += "-charset`nfilename=utf8`n-tagsFromFile`n$($WorkingFiles[$i].original)`n-charset`nfilename=utf8`n-tagsfromfile`n$($WorkingFiles[$i].xmp)`n-charset`nfilename=utf8`n$($WorkingFiles[$i].original).xmp"
        $exiftoolArgList += "-charset`nfilename=utf8`n-tagsFromFile`n$($WorkingFiles[$i].xmp)`n-charset`nfilename=utf8`n-tagsfromfile`n$($WorkingFiles[$i].xmp)`n-overwrite_original`n-charset`nfilename=utf8`n$($WorkingFiles[$i].original).xmp"
    }

    $sw = [diagnostics.stopwatch]::StartNew()
    $k = ($exiftoolInstanceCount - 1)
    # DEFINITION: Pass arguments to Exiftool:
    for($i=0; $i -lt $exiftoolArgList.Length; $i++){
        if($sw.Elapsed.TotalMilliseconds -ge 750){
            Write-Progress -Activity "$choiceString..." -Status "File # $i - $($WorkingFiles[$i].ResultFullName)" -PercentComplete $($i * 100 / $WorkingFiles.Length)
            $sw.Reset()
            $sw.Start()
        }

        if($script:InfoPreference -gt 0){
            [string]$inter = $exiftoolArgList[$i].ToString()
            [string]$inter += "`n-verbose"
            $exiftoolArgList[$i] = $inter
            write-host "exiftool $($exiftoolArgList[$i].Replace("`n"," ").Replace("$((Get-Location).Path)","."))" -ForegroundColor DarkGray
        }

        # $inter = $exiftoolproc[$k]
        try{
            $exiftoolproc[$k].StandardInput.WriteLine("$($exiftoolArgList[$i])`n-execute`n")
            $successcounter++
        }catch{
            write-host "Failed to write StandardInput #$($i.ToString()) to exiftool #$($k.ToString())!" -ForegroundColor Red
            $errorcounter++
        }
        if($k -gt 0){
            $k--
        }else{
            $k = ($exiftoolInstanceCount - 1)
        }
    }
    Write-Progress -Activity "$choiceString..." -Status "Complete!" -Completed

    write-host "Close exiftool down..." -ForegroundColor DarkGray

    # CREDIT: To get asymmetric buffer readout running (ak.a. unlimited processing) (2/2): https://stackoverflow.com/a/24371479/8013879
    [array]$outputerror = @()
    [array]$outputout = @()
    for($i=0; $i -lt $exiftoolInstanceCount; $i++){
        # Close exiftool:
        try{
            $exiftoolproc[$i].StandardInput.WriteLine("-stay_open`nFalse`n")
            $exiftoolproc[$i].WaitForExit()
        }catch{
            write-host "Failed to exit exiftool #$($i.ToString())!" -ForegroundColor Red
            $errorcounter++
        }
        # Unregistering events to retrieve process output.
        try{
            Unregister-Event -SourceIdentifier $exiftoolStdOutEvent[$i].Name
            Unregister-Event -SourceIdentifier $exiftoolStdErrEvent[$i].Name
        }catch{
            write-host "Failed to Unregister-Event #$($i.ToString())!" -ForegroundColor Red
            $errorcounter++
        }

        # Read StdErr and StrOut of exiftool, then print it:
        $outputerror += @($exiftoolStdErrBuilder[$i].ToString().Trim().Split("`r`n",[System.StringSplitOptions]::RemoveEmptyEntries))
        $outputout += @($($exiftoolStdOutBuilder[$i].ToString().Trim().Replace("======== ","").Replace("[1/1]",'').Replace("{ready}","").Replace("1 image files updated","").Replace("  ","").Replace("  ","").Replace("`r`n`r`n","").Split("`r`n",[System.StringSplitOptions]::RemoveEmptyEntries)))
        if($exiftoolproc[$i].ExitCode -ne 0){
            write-host "exiftool #$i's exit code was not 0 (zero)!" -ForegroundColor Magenta
            $errorcounter++
        }
    }

    foreach($i in $outputerror){
        if($outputerror[$i].Length -gt 0){
            write-host "$($outputerror[$i])`t" -ForegroundColor Red -NoNewline
            $errorcounter++
        }
    }
    foreach($i in $outputout){
        if($outputout[$i].Length -gt 0){
            write-host "$($outputout[$i])" -ForegroundColor Yellow
        }
    }

    write-host "Successfully manipulated $successcounter file(s)." -ForegroundColor Gray
}

Start-EXIFManipulation -WorkingFiles $XMP

if((Read-Host "Delete original XMPs?") -eq 1){
    Remove-Item $XMP.xmp
}
