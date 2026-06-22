<#
.SYNOPSIS
Diagnoses Windows profile registration and repairs profile state values.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$Sid=([Security.Principal.WindowsIdentity]::GetCurrent().User.Value),
    [switch]$RepairState,
    [string]$LogRoot="$env:ProgramData\WindowsUserProfileRepair\Logs"
)

Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$runPath=Join-Path $LogRoot (Get-Date -Format 'yyyyMMdd_HHmmss')
$profileList='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'
$keyPath=Join-Path $profileList $Sid
$warnings=New-Object System.Collections.Generic.List[string]

function Test-Admin{
    $id=[Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

try{
    if($env:OS -ne 'Windows_NT'){throw 'Windows is required.'}
    if($RepairState -and -not(Test-Admin)){throw 'Run PowerShell as Administrator for repair mode.'}
    New-Item $runPath -ItemType Directory -Force|Out-Null

    Get-CimInstance Win32_UserProfile|Where-Object SID -eq $Sid|
        Select-Object SID,LocalPath,Loaded,Special,RoamingConfigured,Status,LastUseTime|
        Export-Csv (Join-Path $runPath 'UserProfile.csv') -NoTypeInformation

    $normalExists=Test-Path $keyPath
    $backupExists=Test-Path ($keyPath+'.bak')
    [pscustomobject]@{Sid=$Sid;ProfileKey=$keyPath;NormalKeyExists=$normalExists;BakKeyExists=$backupExists}|
        Export-Csv (Join-Path $runPath 'ProfileRegistration.csv') -NoTypeInformation

    if($normalExists){
        Get-ItemProperty $keyPath|Select-Object ProfileImagePath,State,RefCount,Flags|
            Export-Csv (Join-Path $runPath 'ProfileRegistry-Before.csv') -NoTypeInformation
    }

    if($RepairState){
        if(-not $normalExists){throw 'The normal profile registry key does not exist. No automatic repair was attempted.'}
        if($backupExists){throw 'Both normal and .bak profile keys exist. Resolve the duplicate keys manually after reviewing a registry backup.'}

        reg.exe export 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' (Join-Path $runPath 'ProfileListBackup.reg') /y|
            Out-File (Join-Path $runPath 'RegistryExport.txt')
        if($LASTEXITCODE -ne 0){throw 'ProfileList registry backup failed.'}

        if($PSCmdlet.ShouldProcess($Sid,'Reset profile State and RefCount values')){
            Set-ItemProperty -Path $keyPath -Name State -Type DWord -Value 0 -ErrorAction Stop
            Set-ItemProperty -Path $keyPath -Name RefCount -Type DWord -Value 0 -ErrorAction Stop
            'Restart Windows before testing the repaired profile.'|Out-File (Join-Path $runPath 'RestartRequired.txt')
        }
    }

    if($normalExists){
        $after=Get-ItemProperty $keyPath -ErrorAction Stop
        $after|Select-Object ProfileImagePath,State,RefCount,Flags|
            Export-Csv (Join-Path $runPath 'ProfileRegistry-After.csv') -NoTypeInformation
        if($RepairState -and ($after.State -ne 0 -or $after.RefCount -ne 0)){
            $warnings.Add("Profile state verification failed. State=$($after.State); RefCount=$($after.RefCount)")
        }
    }

    $warnings|Out-File (Join-Path $runPath 'Warnings.txt') -Encoding UTF8
    if($warnings.Count -gt 0){Write-Host "[WARN] Completed with warnings. Logs: $runPath" -ForegroundColor Yellow;exit 2}
    Write-Host "[OK] Completed. Logs: $runPath" -ForegroundColor Green
    exit 0
}catch{Write-Error $_.Exception.Message;exit 1}
