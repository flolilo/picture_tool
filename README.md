# picture_tool
**A tool that works with [ExifTool](https://sno.phy.queensu.ca/~phil/exiftool/) and [ImageMagick](https://www.imagemagick.org/) to let you convert pictures to JPEG and/or transfer metadata. Also, processed files can be moved to the Recycle Bin with [bdukes's `Remove-ItemSafely`](https://github.com/bdukes/PowerShellModules/tree/master/Recycle).**

## Unit testing completed!

All non-generic commands are tested to their extremes with Pester - unicode-signs, brackets, spaces - nothing should break this code now!
Test it for yourself:

```powershell
    # Comment out the script-start:
    (Get-Content .\picture_tool.ps1).replace("Start-Everything -UserParams `$UserParams","# Start-Everything -UserParams `$UserParams") | Set-Content .\picture_tool.ps1 -Encoding UTF8
    Start-Sleep -Milliseconds 100
    # Testing with Pester:
    Invoke-Pester .\picture_tool.tests.ps1 -CodeCoverage .\picture_tool.ps1
    # Uncommenting:
    Start-Sleep -Milliseconds 100
    (Get-Content .\picture_tool.ps1).replace("# Start-Everything -UserParams `$UserParams","Start-Everything -UserParams `$UserParams") | Set-Content .\picture_tool.ps1 -Encoding UTF8
```

As far as I have tested, it even works with PowerShell Core/6!

## Troubleshooting

 - If non-ASCII characters give your script trouble, it might be that it was saved with the wrong encoding. Unfortunately, PowerShell needs **UTF8 with BOM** to function properly _(that is: most of the time, it works perfecly well without it, but once in a while, it will break)_. To check this, I recommend using either [Notepad++](https://notepad-plus-plus.org/) or [VSCode](https://code.visualstudio.com/) (though any advanced text editor will do the job). There, you can change the encoding to UTF with BOM.

 - If the script does not open on your Computer running Windows 7 (or earlier): You need at least PowerShell v3 running on your OS, so [get WMF 5.1](https://www.microsoft.com/en-us/download/details.aspx?id=54616). Also, you need the [Recycle-Module](https://github.com/bdukes/PowerShellModules).
