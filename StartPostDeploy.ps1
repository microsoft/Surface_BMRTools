<#
.SYNOPSIS
    Start post deploy for gBMR image
#>
param (
    # OS Letter for the applied gBMR image
    [Parameter(Mandatory)]
    [string] $OSLetter
)

$Global:ErrorActionPreference = 'Stop'

$LogPath = "$PSScriptRoot\StartPostDeploy.log"
$ErrorLogPath = "$PSScriptRoot\StartPostDeploy.err"
Get-Item $LogPath, $ErrorLogPath -Force -ErrorAction Ignore | Remove-Item -Force 

function Invoke-UpdatesPostDeploy {
    <#
    .SYNOPSIS
        Invoke Updates post deploy.
    .NOTES
        Install updates from "${PostDeployRoot}\updates"
    #>
    [CmdletBinding()]
    param (
        # The root path for post deploy playloads.
        [Parameter(Mandatory)]
        [string] $PostDeployRoot,
        # The drive letter of the OS to be deployed.
        [Parameter(Mandatory)]
        [string] $OSLetter
    )

    $splat = @{
        Path      = $PostDeployRoot
        ChildPath = 'updates'
    }
    $updatesPath = Join-Path @splat
    # foreach .msu or .cab found in updatespath, install it
    if (Test-Path -Path $updatesPath -PathType Container) {
        Write-Host '------------------------------'
        Write-Host 'Post Deploy Updates'
        Write-Host '------------------------------'
        #https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/dism-operating-system-package-servicing-command-line-options?view=windows-11#add-package
        #If /PackagePath points to a folder that contains a .cab or .msu files at its root, any subfolders will also be recursively checked for .cab and .msu files.
        #Acutally, it doesn't do recursion so we have to do recursion by ourselves
        $updates = Get-ChildItem -Path $updatesPath\* -Recurse -Include '*.cab', '*.msu'
        foreach ($update in $updates) {
            Write-Host "Installing update: $($update.FullName)"

            # use dism.exe becasue dism cmdlet was't available in WinRE
            $splat = @(
                "/Image:${OSLetter}:\"
                '/Add-Package'
                "/PackagePath:$($update.FullName)"
                "/ScratchDir:${OSLetter}:\Windows\Temp"
                "/LogPath:${PostDeployRoot}\dism.postdeploy.updates.log"
                '/LogLevel:4'
            )
            Write-Host '    - dism.exe' $splat
            dism.exe @splat | Write-Host
            $ec = $LASTEXITCODE
            if ($ec -ne 0) {
                throw "Dism failed with exit code $ec"
            }
        }
    }
}

function Invoke-DriversPostDeploy {
    <#
    .SYNOPSIS
        Invoke Drivers post deploy.
    .NOTES
        Install drivers from  "${PostDeployRoot}\drivers"
    #>
    [CmdletBinding()]
    param (
        # The root path for post deploy playloads.
        [Parameter(Mandatory)]
        [string] $PostDeployRoot,
        # The drive letter of the OS to be deployed.
        [Parameter(Mandatory)]
        [string] $OSLetter
    )

    $splat = @{
        Path      = $PostDeployRoot
        ChildPath = 'drivers'
    }
    $driversPath = Join-Path @splat
    if (Test-Path -Path $driversPath -PathType Container) {
        Write-Host '------------------------------'
        Write-Host 'Post Deploy Drivers'
        Write-Host '------------------------------'
        
        if (Get-ChildItem -Path $driversPath\* -Recurse -Include '*.inf') {
            Write-Host "Installing drivers from $driversPath"

            # use dism.exe becasue dism cmdlet was't available in WinRE
            $splat = @(
                "/Image:${OSLetter}:\"
                '/Add-Driver'
                "/Driver:${driversPath}"
                "/Recurse"
                "/LogPath:${PostDeployRoot}\dism.postdeploy.drivers.log"
                '/LogLevel:4'
            )
            Write-Host '    - dism.exe' $splat
            dism.exe @splat | Write-Host
            $ec = $LASTEXITCODE
            if ($ec -ne 0) {
                throw "Dism failed with exit code $ec"
            }
        }
    }
}

function StartPostDeploy {
    trap {
        $_
        Write-Host 'Stack Trace'
        Write-Host $_.ScriptStackTrace
    }

    Write-Host "StartPostDeploy"
    Write-Host "OSLetter = $OSLetter"
    Write-Host "LogPath = $LogPath"
    Write-Host "ErrorLogPath = $ErrorLogPath"
    Write-Host "PSScriptRoot = $PSScriptRoot"
    $PostDeployRoot = "$PSScriptRoot\postdeploy"
    Write-Host "PostDeployRoot = $PostDeployRoot"

    Get-ChildItem -Path $PostDeployRoot\* -Include dism.postdeploy.*.log | Remove-Item -Force

    $postDeployFeatures = @(
        'Updates',
        'Drivers'
    )
    
    foreach ($featureName in $postDeployFeatures) {

        $startDateTime = Get-Date
        "Feature $featureName start time: $($startDateTime.ToString("yyyy-MM-dd'T'HH:mm:ss"))" | Write-Host

        $invocationFunctionName = 'Invoke-{0}PostDeploy' -f $featureName
        $invocationFunction = Get-Command -Name $invocationFunctionName -ErrorAction Ignore
        if ($null -eq $invocationFunction) {
            throw [CommandNotFoundException]::new(
                "PostDeploy invocation function $invocationFunctionName not found"
            )
        }
                
        $splat = @{
            PostDeployRoot = $PostDeployRoot
            OSLetter       = $OSLetter
        }
        & $invocationFunction @splat

        $endDateTime = Get-Date
        "Feature $featureName end time: $($endDateTime.ToString("yyyy-MM-dd'T'HH:mm:ss"))" | Write-Host
        $duration = New-TimeSpan -Start $startDateTime -End $endDateTime
        "Feature $featureName duration: $($duration.TotalMinutes) min" | Write-Host
    }
}

Start-Transcript -Path $LogPath
try {
    StartPostDeploy
}
catch {
    $_ | Add-Content -Path $ErrorLogPath
}
finally {
    Stop-Transcript
}