# picture_tool
**A tool that works with [ExifTool](https://sno.phy.queensu.ca/~phil/exiftool/) and [ImageMagick](https://www.imagemagick.org/) to let you convert pictures to JPEG and/or transfer metadata. Also, processed files can be moved to the Recycle Bin with [bdukes's `Remove-ItemSafely`](https://github.com/bdukes/PowerShellModules/tree/master/Recycle).**

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
