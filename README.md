# How to use postdeploy scripts for surface recovery images
* Download surface recovery image from [Surface Recovery Image Download - Microsoft Support](https://support.microsoft.com/en-us/surface-recovery-image)

* Prepare a usbkey containing a partition in fat32 format, assume usbkey root is D: in next following steps

* Extra the image zip file and copy all files to D:

* Download architecture matched PowerShell 7 from [Installing PowerShell on Windows - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.5#zip), extra the zip file of PowerShell 7 and copy all files to D:\sources\pwsh, make sure D:\sources\pwsh\pwsh.exe exists

* Copy [StartPostDeploy.cmd](./StartPostDeploy.cmd) and [StartPostDeploy.ps1](./StartPostDeploy.ps1) to D:\sources

* Add below Run element to D:\sources\ResetConfig.xml
```
<Reset>
 <Run Phase="FactoryReset_AfterImageApply">
   <Path>StartPostDeploy.cmd</Path>
   <Param />
   <Duration>2</Duration>
 </Run>
 …
</Reset>
```

* If you want to post install a latest cumulative update (LCU), please download LCU from [Microsoft Update Catalog](https://www.catalog.update.microsoft.com/Search.aspx?q=cumulative%20update%2024h2), please don't put mutiple \*.msu files into same folder becasue it can cause installation failures, please copy \*.msu files to separate folders in order under D:\sources\postdeploy\updates, like D:\sources\postdeploy\updates\0\\\*.msu, D:\sources\postdeploy\updates\1\\\*.msu, ...

* If you want to post install drivers, please download drivers' msi from [Manage & deploy Surface driver & firmware updates - Surface | Microsoft Learn](https://learn.microsoft.com/en-us/surface/manage-surface-driver-and-firmware-updates#download-and-install-updates), please use msiexec to expand msi file like below, and then copy drivers you want to install from SurfaceUpdate sub folder under msi expanded destination to D:\sources\postdeploy\drivers
```powershell
msiexec /a "C:\Path\To\Installer.msi" /qb TARGETDIR="C:\Path\To\ExtractedFiles"
```

* Please connect the usbkey to the surface device you have to install surface recovery image with postdeploy supported after above steps done

* Please collect logs C:\$SysReset\Logs\setupact.log, D:\sources\postdeploy\StartPostDeploy.log and D:\sources\postdeploy\StartPostDeploy.err to double check if postdeploy succeeded as expected, the existence of D:\sources\postdeploy\StartPostDeploy.err means there are postdeploy failures.

# Known issues
* If you put KB5043080 and latest LCU into same folder under <usbroot>\sources\postdeploy\updates, KB5043080 installation will fail
* Removing existing higher version drivers is not supported, if you want to post install lower version drivers please customize StartPostDeploy.ps1 by yourself

# Reference Documents
* [Add extensibility scripts to push-button reset | Microsoft Learn](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/add-a-script-to-push-button-reset-features?view=windows-11)