# picture_tool
**A tool that works with [ExifTool](https://sno.phy.queensu.ca/~phil/exiftool/) and [ImageMagick](https://www.imagemagick.org/) to let you convert pictures to JPEG and/or transfer metadata. Also, processed files can be moved to the Recycle Bin with [bdukes's `Remove-ItemSafely`](https://github.com/bdukes/PowerShellModules/tree/master/Recycle).**

All non-generic commands are tested to their extremes with Pester - unicode-signs, brackets, spaces - nothing should break this code now!
Test it for yourself:

```powershell
    Invoke-Pester .\picture_tool.tests.ps1 -CodeCoverage .\picture_tool.ps1
```
